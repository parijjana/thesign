<#
.SYNOPSIS
  Deterministic build/deploy for The Sign — Windows or the Android device.

.DESCRIPTION
  Captures the verified deploy path (incl. the Android-specific fixes) so it can
  run with NO LLM in the loop: CI, a pre-push hook, or a scheduled job. Every
  step is logged to build/deploy-logs/. The script handles the known happy path
  and the two known Android gotchas on its own; on any failure it stops, leaves
  the full log, and exits non-zero — so a human or an LLM can review the log
  after the fact instead of babysitting the run.

  Idempotent: safe to re-run. Re-discovering these steps interactively is what
  the matching .claude/skills/run-app skill avoids.

.PARAMETER Target
  windows      -> flutter build windows --debug   (build only; no device needed)
  android      -> ensure android scaffold + kotlin fix, then build the debug APK
  android-run  -> android, then install + launch on the device

.PARAMETER DeviceId
  Android device id (e.g. ZD222W79GV). Auto-detected from `flutter devices` if
  omitted.

.EXAMPLE
  pwsh tool/deploy.ps1 -Target android-run
#>
[CmdletBinding()]
param(
  [ValidateSet('windows', 'android', 'android-run')]
  [string]$Target = 'windows',
  [string]$DeviceId = ''
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$logDir = Join-Path $repo 'build/deploy-logs'
New-Item -ItemType Directory -Force $logDir | Out-Null
$log = Join-Path $logDir ("deploy-$Target-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Log([string]$m) {
  "[{0}] {1}" -f (Get-Date -Format o), $m | Tee-Object -FilePath $log -Append | Out-Null
}

# Run a native command, streaming combined output to the log. Returns exit code.
# NB: do not name the param $args — it shadows PowerShell's automatic $args and
# @args would splat the (empty) automatic one.
function Invoke-Logged([string]$exe, [string[]]$argv) {
  Log "RUN: $exe $($argv -join ' ')"
  # Tee-Object passes objects THROUGH; send them to Out-Null so they don't
  # pollute the function's return value (only the exit code should come back).
  & $exe @argv 2>&1 | Tee-Object -FilePath $log -Append | Out-Null
  return $LASTEXITCODE
}

function Fail([string]$m) {
  Log "FAIL: $m"
  Write-Host "DEPLOY FAILED — see $log" -ForegroundColor Red
  exit 1
}

Log "=== deploy target=$Target repo=$repo ==="

# --- Android preconditions (the two non-obvious fixes) ----------------------
if ($Target -like 'android*') {
  # 1) The project ships web+Windows only; scaffold android/ if absent.
  if (-not (Test-Path (Join-Path $repo 'android'))) {
    Log 'android/ missing -> flutter create --platforms=android .'
    if ((Invoke-Logged 'flutter' @('create', '--platforms=android', '.')) -ne 0) {
      Fail 'flutter create (android scaffold) failed'
    }
    # flutter create drops a boilerplate counter test that breaks `flutter test`.
    Remove-Item -Force (Join-Path $repo 'test/widget_test.dart') -ErrorAction SilentlyContinue
  }

  # 2) Kotlin incremental compilation breaks when the pub cache and the project
  #    live on different drive roots (C: vs D:): its relocatable cache can't make
  #    a cross-root relative path. Force non-incremental.
  $gp = Join-Path $repo 'android/gradle.properties'
  if (-not (Select-String -Path $gp -SimpleMatch 'kotlin.incremental=false' -Quiet)) {
    Log 'adding kotlin.incremental=false to android/gradle.properties'
    Add-Content -Path $gp -Value "`nkotlin.incremental=false"
  }

  if (-not $DeviceId -and $Target -eq 'android-run') {
    try {
      $dev = flutter devices --machine 2>$null | ConvertFrom-Json |
        Where-Object { $_.targetPlatform -like 'android*' } | Select-Object -First 1
      if ($dev) { $DeviceId = $dev.id; Log "auto-detected device: $DeviceId" }
    } catch { }
    if (-not $DeviceId) { Fail 'no Android device found (connect one or pass -DeviceId)' }
  }
}

# --- Build (with one clean-retry for the known Kotlin cache corruption) ------
function Build-Android {
  $code = Invoke-Logged 'flutter' @('build', 'apk', '--debug')
  if ($code -ne 0) {
    # The incremental-cache corruption leaves a poisoned plugin cache; clearing
    # it and retrying once recovers without a full `flutter clean`.
    Log 'android build failed -> clearing kotlin caches and retrying once'
    Remove-Item -Recurse -Force (Join-Path $repo 'build/shared_preferences_android') -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force (Join-Path $repo 'android/.kotlin') -ErrorAction SilentlyContinue
    $code = Invoke-Logged 'flutter' @('build', 'apk', '--debug')
  }
  return $code
}

switch ($Target) {
  'windows' {
    if ((Invoke-Logged 'flutter' @('build', 'windows', '--debug')) -ne 0) { Fail 'windows build failed' }
  }
  'android' {
    if ((Build-Android) -ne 0) { Fail 'android apk build failed' }
  }
  'android-run' {
    if ((Build-Android) -ne 0) { Fail 'android apk build failed' }
    if ((Invoke-Logged 'flutter' @('install', '-d', $DeviceId)) -ne 0) { Fail "install on $DeviceId failed" }
  }
}

Log "=== deploy OK ==="
Write-Host "DEPLOY OK — log: $log" -ForegroundColor Green
exit 0
