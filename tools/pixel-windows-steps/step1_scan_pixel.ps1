<#
.SYNOPSIS
  [STEP 1 - SCAN & ANALYZE GOOGLE PIXEL] (100% Read-Only - Safe Mode)
  Auto-downloads ADB if missing, verifies connection, backs up package list to Desktop,
  collects Hardware, Battery Health/Cycle Count, Storage, RAM, Modem settings,
  User Apps & System Packages, exports a .md file to Desktop AND copies to Clipboard.

.USAGE
  powershell -ExecutionPolicy Bypass -File .\step1_scan_pixel.ps1
#>

param(
    [string]$Device = ""
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   STEP 1: GOOGLE PIXEL DEEP SCAN & DIAGNOSTICS           " -ForegroundColor Cyan
Write-Host "   (Safe Read-Only Mode: No changes made to device)       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# ---------- 1. Prepare ADB ----------
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    $WorkDir = "C:\adb_work"
    $AdbExe = "$WorkDir\platform-tools\adb.exe"
    if (-not (Test-Path $AdbExe)) {
        Write-Host "`n[*] ADB not found. Downloading Google Platform-Tools (~12MB)..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
        $ZipPath = "$WorkDir\platform-tools.zip"
        Invoke-WebRequest -Uri "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $WorkDir -Force
        Remove-Item $ZipPath -Force
    }
    $env:Path = "$WorkDir\platform-tools;" + $env:Path
}

$adbArgs = @()
if ($Device) { $adbArgs = @("-s", $Device) }

Write-Host "`n[*] Checking ADB connection..." -ForegroundColor Cyan
$devices = (& adb @adbArgs devices) | Select-Object -Skip 1 | Where-Object { $_ -match "\t(device|unauthorized)$" }
if (-not $devices) {
    Write-Host "[!] No Android device connected!" -ForegroundColor Red
    Write-Host "    1. On Pixel: Settings -> About phone -> Tap 'Build number' 7 times." -ForegroundColor Yellow
    Write-Host "    2. Settings -> System -> Developer options -> Enable 'USB debugging' (or Wireless debugging)." -ForegroundColor Yellow
    Write-Host "    3. Connect USB cable (or run step0_connect_wifi.ps1) and tap 'Allow' on phone." -ForegroundColor Yellow
    exit 1
}
if ($devices -match "unauthorized") {
    Write-Host "[!] Device is waiting for authorization on phone screen!" -ForegroundColor Yellow
    Write-Host "    -> Check your Pixel screen, tick 'Always allow from this computer' and tap 'Allow'." -ForegroundColor Yellow
    exit 1
}

# ---------- 2. Collect Diagnostics ----------
Write-Host "[*] Reading Hardware, Battery, RAM, Storage, Settings and Packages..." -ForegroundColor Green

$Brand       = ((& adb @adbArgs shell getprop ro.product.brand) -join "").Trim()
$Model       = ((& adb @adbArgs shell getprop ro.product.model) -join "").Trim()
$DeviceCode  = ((& adb @adbArgs shell getprop ro.product.device) -join "").Trim()
$SoC         = ((& adb @adbArgs shell getprop ro.hardware.chipname) -join "").Trim()
if (-not $SoC) { $SoC = ((& adb @adbArgs shell getprop ro.board.platform) -join "").Trim() }
$AndroidVer  = ((& adb @adbArgs shell getprop ro.build.version.release) -join "").Trim()
$BuildId     = ((& adb @adbArgs shell getprop ro.build.id) -join "").Trim()
$SecPatch    = ((& adb @adbArgs shell getprop ro.build.version.security_patch) -join "").Trim()
$Baseband    = ((& adb @adbArgs shell getprop gsm.version.baseband) -join "").Trim()

# Output files on Desktop
$Timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$DesktopDir = [Environment]::GetFolderPath("Desktop")
$SafeModel  = if ($Model) { $Model -replace '\s+', '_' } else { "Device" }
$BackupFile = Join-Path $DesktopDir "Pixel_${SafeModel}_packages_backup_${Timestamp}.txt"
$ReportFile = Join-Path $DesktopDir "Pixel_${SafeModel}_Step1_Scan.md"

$AllEnabledPkgs = (& adb @adbArgs shell pm list packages -e) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object
$AllUserPkgs    = (& adb @adbArgs shell pm list packages -3) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object
$AllSystemPkgs  = (& adb @adbArgs shell pm list packages -s -e) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object
$AllDisabled    = (& adb @adbArgs shell pm list packages -d) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object

$AllEnabledPkgs | Set-Content -Path $BackupFile -Encoding UTF8

# Battery & Temperature
$BatteryDump = (& adb @adbArgs shell "dumpsys battery") -join "`n"
$BattCycle   = ((& adb @adbArgs shell "cat /sys/class/power_supply/battery/cycle_count 2>/dev/null") -join "").Trim()
$BattFull    = ((& adb @adbArgs shell "cat /sys/class/power_supply/battery/charge_full 2>/dev/null") -join "").Trim()
$BattDesign  = ((& adb @adbArgs shell "cat /sys/class/power_supply/battery/charge_full_design 2>/dev/null") -join "").Trim()

# Storage & RAM
$StorageDf   = (& adb @adbArgs shell "df -h /data") -join "`n"
$MemInfo     = (& adb @adbArgs shell "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree'") -join "`n"
$TopMem      = (& adb @adbArgs shell "dumpsys meminfo | sed -n '/Total PSS by process:/,/Total PSS by OOM adjustment:/p' | head -n 25") -join "`n"

# System Settings
$MobAlwaysOn = ((& adb @adbArgs shell "settings get global mobile_data_always_on") -join "").Trim()
$WifiScan    = ((& adb @adbArgs shell "settings get global wifi_scan_always_enabled") -join "").Trim()
$BleScan     = ((& adb @adbArgs shell "settings get global ble_scan_always_enabled") -join "").Trim()
$AdpConn     = ((& adb @adbArgs shell "settings get secure adaptive_connectivity_enabled") -join "").Trim()
$AnimWin     = ((& adb @adbArgs shell "settings get global window_animation_scale") -join "").Trim()
$AnimTrans   = ((& adb @adbArgs shell "settings get global transition_animation_scale") -join "").Trim()
$AnimDur     = ((& adb @adbArgs shell "settings get global animator_duration_scale") -join "").Trim()
$PeakRefresh = ((& adb @adbArgs shell "settings get system peak_refresh_rate") -join "").Trim()
$MinRefresh  = ((& adb @adbArgs shell "settings get system min_refresh_rate") -join "").Trim()
$MaxCached   = (& adb @adbArgs shell "dumpsys activity settings | grep -i cur_max_cached") -join "`n"

# Generate Markdown Report (.md)
$ReportLines = @(
    "# Google Pixel Scan Report (Step 1 - Scan)"
    ""
    "- **Scan Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Device:** $Brand $Model (Codename: ``$DeviceCode``)"
    "- **Chip / SoC:** ``$SoC``"
    "- **OS Version:** Android $AndroidVer (Build: ``$BuildId`` | Security Patch: ``$SecPatch``)"
    "- **Baseband Modem:** ``$Baseband``"
    ""
    "## 1. Battery Health & Temperature"
    "- **Kernel Cycle Count:** ``$BattCycle``"
    "- **Kernel Charge Full (uAh):** ``$BattFull``"
    "- **Kernel Charge Design (uAh):** ``$BattDesign``"
    "``````text"
    $BatteryDump
    "``````"
    ""
    "## 2. Internal Storage (/data)"
    "``````text"
    $StorageDf
    "``````"
    ""
    "## 3. RAM & Swap Info"
    "``````text"
    $MemInfo
    "``````"
    ""
    "## 4. Current System Settings"
    "| Setting Key | Current Value |"
    "| :--- | :--- |"
    "| ``mobile_data_always_on`` | ``$MobAlwaysOn`` |"
    "| ``wifi_scan_always_enabled`` | ``$WifiScan`` |"
    "| ``ble_scan_always_enabled`` | ``$BleScan`` |"
    "| ``adaptive_connectivity_enabled`` | ``$AdpConn`` |"
    "| ``window_animation_scale`` | ``$AnimWin`` |"
    "| ``transition_animation_scale`` | ``$AnimTrans`` |"
    "| ``animator_duration_scale`` | ``$AnimDur`` |"
    "| ``peak_refresh_rate`` | ``$PeakRefresh`` |"
    "| ``min_refresh_rate`` | ``$MinRefresh`` |"
    "| ``max_cached_processes`` | ``$MaxCached`` |"
    ""
    "## 5. Top RAM Consuming Processes"
    "``````text"
    $TopMem
    "``````"
    ""
    "## 6. User Installed Apps ($($AllUserPkgs.Count) apps)"
    "``````text"
    ($AllUserPkgs -join "`n")
    "``````"
    ""
    "## 7. Enabled System Packages ($($AllSystemPkgs.Count) packages)"
    "``````text"
    ($AllSystemPkgs -join "`n")
    "``````"
    ""
    "## 8. Already Disabled / Uninstalled Packages ($($AllDisabled.Count) packages)"
    "``````text"
    ($AllDisabled -join "`n")
    "``````"
)

$ReportText = $ReportLines -join "`r`n"
$ReportText | Set-Content -Path $ReportFile -Encoding UTF8

try {
    $ReportText | Set-Clipboard
    Write-Host "`n[OK] COPIED REPORT TO CLIPBOARD & EXPORTED .MD TO DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] EXPORTED .MD REPORT TO DESKTOP!" -ForegroundColor Green
}

Write-Host "`n--- STEP 1 SUMMARY ---" -ForegroundColor Cyan
Write-Host "Device          : $Brand $Model ($DeviceCode) - Chip $SoC - Android $AndroidVer"
Write-Host "Active Packages : $($AllEnabledPkgs.Count) (User Apps: $($AllUserPkgs.Count) | System: $($AllSystemPkgs.Count))"
Write-Host "Markdown Report : $ReportFile" -ForegroundColor Yellow
Write-Host "Backup File     : $BackupFile"
Write-Host "-> Press Ctrl+V to paste the report directly, or send the .md file from your Desktop!" -ForegroundColor Green
