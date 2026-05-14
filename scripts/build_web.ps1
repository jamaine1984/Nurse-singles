param(
  [switch]$NoPub
)

$ErrorActionPreference = 'Stop'

function Read-EnvFile([string]$Path, [hashtable]$Values) {
  if (!(Test-Path $Path)) { return }
  Get-Content -Path $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith('#')) { return }
    $parts = $line.Split('=', 2)
    if ($parts.Length -ne 2) { return }
    $Values[$parts[0].Trim()] = $parts[1].Trim()
  }
}

function First-Value([hashtable]$Values, [string[]]$Keys) {
  foreach ($key in $Keys) {
    if ($Values.ContainsKey($key) -and $Values[$key]) {
      return $Values[$key]
    }
    $envValue = [Environment]::GetEnvironmentVariable($key)
    if ($envValue) {
      return $envValue
    }
  }
  return $null
}

$values = @{}
Read-EnvFile '.env' $values
Read-EnvFile '.env.local' $values
Read-EnvFile '.env.release.local' $values

$defines = @{}
$revenueCatKey = First-Value $values @('REVENUECAT_PUBLIC_API_KEY', 'REVENUECAT_API_KEY')
$revenueCatWebKey = First-Value $values @('REVENUECAT_WEB_PUBLIC_API_KEY')
$zegoAppId = First-Value $values @('ZEGO_APP_ID', 'ZEGOCLOUD_APP_ID')
$zegoAppSign = First-Value $values @('ZEGO_APP_SIGN', 'ZEGOCLOUD_APP_SIGN')
$environment = First-Value $values @('ENVIRONMENT')
$appCheckWebRecaptchaSiteKey = First-Value $values @(
  'APP_CHECK_WEB_RECAPTCHA_ENTERPRISE_SITE_KEY',
  'APP_CHECK_WEB_RECAPTCHA_SITE_KEY'
)
$appCheckWebProvider = First-Value $values @('APP_CHECK_WEB_PROVIDER')

if ($revenueCatKey) { $defines['REVENUECAT_PUBLIC_API_KEY'] = $revenueCatKey }
if ($revenueCatWebKey) { $defines['REVENUECAT_WEB_PUBLIC_API_KEY'] = $revenueCatWebKey }
if ($zegoAppId) { $defines['ZEGO_APP_ID'] = $zegoAppId }
if ($zegoAppSign) { $defines['ZEGO_APP_SIGN'] = $zegoAppSign }
if ($environment) { $defines['ENVIRONMENT'] = $environment }
if ($appCheckWebRecaptchaSiteKey) {
  $defines['APP_CHECK_WEB_RECAPTCHA_SITE_KEY'] = $appCheckWebRecaptchaSiteKey
}
if ($appCheckWebProvider) {
  $defines['APP_CHECK_WEB_PROVIDER'] = $appCheckWebProvider
}

if ($revenueCatKey) {
  $lowerRevenueCatKey = $revenueCatKey.ToLowerInvariant()
  if ($lowerRevenueCatKey.StartsWith('test_') -or $lowerRevenueCatKey.StartsWith('sk_')) {
    throw 'Web release builds require the RevenueCat public production SDK key. Do not use a Test Store key or secret API key.'
  }
}
if ($revenueCatWebKey) {
  $lowerRevenueCatWebKey = $revenueCatWebKey.ToLowerInvariant()
  if ($lowerRevenueCatWebKey.StartsWith('test_') -or $lowerRevenueCatWebKey.StartsWith('sk_')) {
    throw 'Web release builds require the RevenueCat Web Billing public SDK key. Do not use a Test Store key or secret API key.'
  }
} elseif ($revenueCatKey -and $revenueCatKey.ToLowerInvariant().StartsWith('goog_')) {
  Write-Warning 'REVENUECAT_WEB_PUBLIC_API_KEY is missing. The web build will initialize with the Google Play key and Web Billing products may not load.'
}

$flutterArgs = @('build', 'web', '--release')
if ($NoPub) { $flutterArgs += '--no-pub' }

foreach ($key in $defines.Keys) {
  $flutterArgs += "--dart-define=$key=$($defines[$key])"
}

$redactedDefines = if ($defines.Count -gt 0) {
  ($defines.Keys | Sort-Object | ForEach-Object { "--dart-define=$_=<redacted>" }) -join ' '
} else {
  'none'
}
Write-Host "Running flutter build web with dart-defines: $redactedDefines"
flutter @flutterArgs

Get-ChildItem -LiteralPath 'build\web' -Filter 'flutter_bootstrap.*.js' -File -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath 'build\web' -Filter 'main.dart.*.js' -File -ErrorAction SilentlyContinue | Remove-Item -Force

$publicRoot = (Resolve-Path public).Path
Get-ChildItem -LiteralPath public -Recurse -File | ForEach-Object {
  $relativePath = $_.FullName.Substring($publicRoot.Length).TrimStart('\', '/')
  if ($relativePath -eq 'index.html') {
    return
  }

  $destination = Join-Path 'build\web' $relativePath
  $destinationDirectory = Split-Path -Parent $destination
  if ($destinationDirectory -and !(Test-Path $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
  }
  Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
}

$indexPath = Join-Path 'build\web' 'index.html'
if (Test-Path $indexPath) {
  $bootstrapVersion = Get-Date -Format 'yyyyMMddHHmmss'
  $bootstrapSource = Join-Path 'build\web' 'flutter_bootstrap.js'
  $bootstrapFileName = "flutter_bootstrap.$bootstrapVersion.js"
  $mainSource = Join-Path 'build\web' 'main.dart.js'
  $mainFileName = "main.dart.$bootstrapVersion.js"
  if (Test-Path $mainSource) {
    Copy-Item -LiteralPath $mainSource -Destination (Join-Path 'build\web' $mainFileName) -Force
  }
  if (Test-Path $bootstrapSource) {
    $bootstrapDestination = Join-Path 'build\web' $bootstrapFileName
    Copy-Item -LiteralPath $bootstrapSource -Destination $bootstrapDestination -Force
    $bootstrapContent = Get-Content -LiteralPath $bootstrapDestination -Raw
    $bootstrapContent = $bootstrapContent -replace '"mainJsPath":"main\.dart\.js"', "`"mainJsPath`":`"$mainFileName`""
    Set-Content -LiteralPath $bootstrapDestination -Value $bootstrapContent -NoNewline
  }
  $indexHtml = Get-Content -LiteralPath $indexPath -Raw
  $indexHtml = $indexHtml -replace 'flutter_bootstrap(\.\d{14})?\.js(\?v=[^"]*)?', $bootstrapFileName
  Set-Content -LiteralPath $indexPath -Value $indexHtml -NoNewline
}
