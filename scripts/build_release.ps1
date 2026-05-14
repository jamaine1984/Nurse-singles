param(
  [ValidateSet('appbundle', 'apk', 'debug-apk')]
  [string]$Target = 'appbundle',
  [switch]$NoPub,
  [switch]$NoShrink
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
$appCheckAndroidProvider = First-Value $values @('APP_CHECK_ANDROID_PROVIDER')

if ($revenueCatKey) { $defines['REVENUECAT_PUBLIC_API_KEY'] = $revenueCatKey }
if ($zegoAppId) { $defines['ZEGO_APP_ID'] = $zegoAppId }
if ($zegoAppSign) { $defines['ZEGO_APP_SIGN'] = $zegoAppSign }
if ($environment) { $defines['ENVIRONMENT'] = $environment }
if ($appCheckAndroidProvider) { $defines['APP_CHECK_ANDROID_PROVIDER'] = $appCheckAndroidProvider }

if ($Target -ne 'debug-apk' -and $revenueCatKey) {
  $lowerRevenueCatKey = $revenueCatKey.ToLowerInvariant()
  if ($lowerRevenueCatKey.StartsWith('test_') -or $lowerRevenueCatKey.StartsWith('sk_')) {
    throw 'Release builds require the RevenueCat public production SDK key. Do not use a Test Store key or secret API key for Google Play releases.'
  }
}

$flutterArgs = @('build')
if ($Target -eq 'appbundle') {
  $flutterArgs += 'appbundle'
  $flutterArgs += '--release'
} elseif ($Target -eq 'apk') {
  $flutterArgs += 'apk'
  $flutterArgs += '--release'
} else {
  $flutterArgs += 'apk'
  $flutterArgs += '--debug'
}

if ($NoPub) { $flutterArgs += '--no-pub' }
if ($NoShrink -and $Target -ne 'debug-apk') { $flutterArgs += '--no-shrink' }

foreach ($key in $defines.Keys) {
  $flutterArgs += "--dart-define=$key=$($defines[$key])"
}

$missing = @()
if (!$revenueCatKey) { $missing += 'REVENUECAT_PUBLIC_API_KEY' }
if (!$zegoAppId) { $missing += 'ZEGO_APP_ID' }
if (!$zegoAppSign) { $missing += 'ZEGO_APP_SIGN' }
if ($missing.Count -gt 0) {
  Write-Warning "Missing local release config: $($missing -join ', '). The build can finish, but those features will be disabled or incomplete."
}

$redactedDefines = if ($defines.Count -gt 0) {
  ($defines.Keys | Sort-Object | ForEach-Object { "--dart-define=$_=<redacted>" }) -join ' '
} else {
  'none'
}
Write-Host "Running flutter build for $Target with dart-defines: $redactedDefines"
flutter @flutterArgs
