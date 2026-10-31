<#
.SYNOPSIS
  [STEP 3 - OPTIMIZE MODEM, BATTERY & SMOOTHNESS FOR GOOGLE PIXEL]
  Applies safe system optimizations for Google Pixel:
  1. Disables background mobile data while on Wi-Fi (mobile_data_always_on = 0) to reduce modem heat & idle drain.
  2. Disables 24/7 background Wi-Fi & BLE scanning.
  3. Sets Animation scales to 0.5x for snappy UI response.
  4. Unlocks full RAM multitasking for Pixel (removes artificial max_cached_processes caps).
  5. Trims system caches & runs AOT compilation (bg-dexopt-job).
  Exports .md report to Desktop AND copies to Clipboard.

.USAGE
  Full optimization:
    powershell -ExecutionPolicy Bypass -File .\step3_optimize_pixel.ps1

  Fast mode (skip 60s AOT dexopt compilation):
    powershell -ExecutionPolicy Bypass -File .\step3_optimize_pixel.ps1 -SkipDexopt
#>

param(
    [double]$AnimationScale = 0.5,
    [switch]$SkipModemTune,
    [switch]$SkipDexopt,
    [string]$Device = ""
)

$ErrorActionPreference = "Continue"

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\adb_work\platform-tools\adb.exe") {
        $env:Path = "C:\adb_work\platform-tools;" + $env:Path
    } else {
        Write-Host "[!] ADB not found. Run step1_scan_pixel.ps1 first!" -ForegroundColor Red
        exit 1
    }
}

$adbArgs = @()
if ($Device) { $adbArgs = @("-s", $Device) }

$Model      = ((& adb @adbArgs shell getprop ro.product.model) -join "").Trim()
$SafeModel  = if ($Model) { $Model -replace '\s+', '_' } else { "Device" }
$DesktopDir = [Environment]::GetFolderPath("Desktop")
$ReportFile = Join-Path $DesktopDir "Pixel_${SafeModel}_Step3_Optimize.md"

$BeforeAnim  = ((& adb @adbArgs shell "settings get global window_animation_scale") -join "").Trim()
$BeforeMob   = ((& adb @adbArgs shell "settings get global mobile_data_always_on") -join "").Trim()
$BeforeWifi  = ((& adb @adbArgs shell "settings get global wifi_scan_always_enabled") -join "").Trim()
$BeforeBle   = ((& adb @adbArgs shell "settings get global ble_scan_always_enabled") -join "").Trim()

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   STEP 3: GOOGLE PIXEL MODEM, BATTERY & UI OPTIMIZATION  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Animation Scale
Write-Host "`n[1/5] Setting UI Animation Scale to ${AnimationScale}x..." -ForegroundColor White
& adb @adbArgs shell "settings put global window_animation_scale $AnimationScale" 2>$null
& adb @adbArgs shell "settings put global transition_animation_scale $AnimationScale" 2>$null
& adb @adbArgs shell "settings put global animator_duration_scale $AnimationScale" 2>$null
Write-Host "      -> Animation Scale set to ${AnimationScale}x!" -ForegroundColor Green

# 2. Modem & Background Scanning
if (-not $SkipModemTune) {
    Write-Host "`n[2/5] Optimizing Modem & Disabling 24/7 Background Scanning..." -ForegroundColor White
    & adb @adbArgs shell "settings put global mobile_data_always_on 0" 2>$null
    & adb @adbArgs shell "settings put global wifi_scan_always_enabled 0" 2>$null
    & adb @adbArgs shell "settings put global ble_scan_always_enabled 0" 2>$null
    Write-Host "      -> Disabled mobile_data_always_on (0) & wifi/ble_scan_always_enabled (0)!" -ForegroundColor Green
}

# 3. RAM Multitasking
Write-Host "`n[3/5] Unlocking native RAM multitasking limit on Pixel..." -ForegroundColor White
& adb @adbArgs shell "device_config delete activity_manager max_cached_processes" 2>$null
Write-Host "      -> Unlocked native RAM manager!" -ForegroundColor Green

# 4. Trim Caches
Write-Host "`n[4/5] Trimming system caches (pm trim-caches)..." -ForegroundColor White
& adb @adbArgs shell "pm trim-caches 999999999999999999" 2>$null
Write-Host "      -> System caches trimmed!" -ForegroundColor Green

# 5. AOT Dexopt
$DexoptStatus = "Skipped (-SkipDexopt)"
if (-not $SkipDexopt) {
    Write-Host "`n[5/5] Running AOT app optimization (bg-dexopt-job, takes ~30-90s)..." -ForegroundColor Yellow
    & adb @adbArgs shell "cmd package bg-dexopt-job" | Out-Null
    Write-Host "      -> AOT compilation completed!" -ForegroundColor Green
    $DexoptStatus = "Completed (bg-dexopt-job)"
} else {
    Write-Host "`n[5/5] Skipped bg-dexopt-job as requested." -ForegroundColor DarkGray
}

$AfterAnim  = ((& adb @adbArgs shell "settings get global window_animation_scale") -join "").Trim()
$AfterMob   = ((& adb @adbArgs shell "settings get global mobile_data_always_on") -join "").Trim()
$AfterWifi  = ((& adb @adbArgs shell "settings get global wifi_scan_always_enabled") -join "").Trim()
$AfterBle   = ((& adb @adbArgs shell "settings get global ble_scan_always_enabled") -join "").Trim()

$MdReport = @(
    "# Google Pixel Optimization Report (Step 3 - Optimize)"
    ""
    "- **Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Device:** $Model"
    ""
    "## Before vs. After Settings"
    "| Setting | Before | After | Purpose |"
    "| :--- | :---: | :---: | :--- |"
    "| ``window_animation_scale`` | ``$BeforeAnim`` | ``$AfterAnim`` | Faster UI transitions (0.5x) |"
    "| ``mobile_data_always_on`` | ``$BeforeMob`` | ``$AfterMob`` | Turn off idle 4G/5G drain while on Wi-Fi |"
    "| ``wifi_scan_always_enabled`` | ``$BeforeWifi`` | ``$AfterWifi`` | Stop 24/7 background Wi-Fi scanning |"
    "| ``ble_scan_always_enabled`` | ``$BeforeBle`` | ``$AfterBle`` | Stop 24/7 background Bluetooth BLE scanning |"
    "| ``max_cached_processes`` | - | ``Default (Unlocked)`` | Full RAM multitasking for Pixel |"
    "| ``pm trim-caches`` | - | ``Trimmed`` | Free temporary system caches |"
    "| ``bg-dexopt-job`` (AOT) | - | ``$DexoptStatus`` | Pre-compile app code for faster launch |"
) -join "`r`n"

$MdReport | Set-Content -Path $ReportFile -Encoding UTF8
try {
    $MdReport | Set-Clipboard
    Write-Host "`n[OK] COPIED STEP 3 REPORT TO CLIPBOARD & EXPORTED .MD TO DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] EXPORTED STEP 3 .MD REPORT TO DESKTOP!" -ForegroundColor Green
}
Write-Host "Markdown Report: $ReportFile" -ForegroundColor Yellow
