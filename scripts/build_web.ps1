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
$zegoAppId = First-Value $values @('ZEGO_APP_ID', 'ZEGOCLOUD_APP_ID')
$zegoAppSign = First-Value $values @('ZEGO_APP_SIGN', 'ZEGOCLOUD_APP_SIGN')
$environment = First-Value $values @('ENVIRONMENT')

if ($revenueCatKey) { $defines['REVENUECAT_PUBLIC_API_KEY'] = $revenueCatKey }
if ($zegoAppId) { $defines['ZEGO_APP_ID'] = $zegoAppId }
if ($zegoAppSign) { $defines['ZEGO_APP_SIGN'] = $zegoAppSign }
if ($environment) { $defines['ENVIRONMENT'] = $environment }

if ($revenueCatKey) {
  $lowerRevenueCatKey = $revenueCatKey.ToLowerInvariant()
  if ($lowerRevenueCatKey.StartsWith('test_') -or $lowerRevenueCatKey.StartsWith('sk_')) {
    throw 'Web release builds require the RevenueCat public production SDK key. Do not use a Test Store key or secret API key.'
  }
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
