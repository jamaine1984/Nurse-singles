param(
  [string]$AdbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
)

$ErrorActionPreference = 'Stop'
$packageName = 'com.nursesingles.international'
$prefsName = 'shared_prefs/com.google.firebase.appcheck.debug.store.W0RFRkFVTFRd+MTo3MDY0OTMwNDAxOTA6YW5kcm9pZDozOTZlOGM2MTkyZjdiOWRmZjEzMzZm.xml'

if (!(Test-Path $AdbPath)) {
  throw "adb.exe not found at $AdbPath"
}

$devices = & $AdbPath devices -l |
  Select-String -Pattern 'device product:' |
  ForEach-Object {
    $parts = $_.Line -split '\s+'
    [pscustomobject]@{
      Serial = $parts[0]
      Detail = $_.Line.Trim()
    }
  }

if (!$devices) {
  Write-Host 'No connected Android devices found.'
  exit 0
}

foreach ($device in $devices) {
  $xml = & $AdbPath -s $device.Serial shell run-as $packageName cat $prefsName 2>$null
  $token = ($xml | Select-String -Pattern 'DEBUG_SECRET">([^<]+)' |
    ForEach-Object { $_.Matches[0].Groups[1].Value } |
    Select-Object -First 1)

  Write-Host "Device: $($device.Detail)"
  if ($token) {
    Write-Host "App Check debug token: $token"
  } else {
    Write-Host 'App Check debug token not found. Launch the debug app once, then rerun this script.'
  }
  Write-Host ''
}
