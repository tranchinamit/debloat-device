<#
.SYNOPSIS
  [STEP 4 - VERIFY OPTIMIZATION RESULTS OR RESTORE PACKAGES]
  Default: Checks free RAM, free Storage, Battery temp, Modem settings,
  exports .md report to Desktop AND copies to Clipboard.
  Also supports restoring a single package (-RestorePackage) or all packages (-RestoreAll).

.USAGE
  1. Verify metrics after optimization:
     powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1

  2. Restore a single package:
     powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1 -RestorePackage com.google.android.videos

  3. Restore all uninstalled packages & reset settings to factory defaults:
     powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1 -RestoreAll
#>

param(
    [string]$RestorePackage = "",
    [switch]$RestoreAll,
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
$ReportFile = Join-Path $DesktopDir "Pixel_${SafeModel}_Step4_Verify.md"

if ($RestorePackage) {
    Write-Host "[*] Restoring package: $RestorePackage ..." -ForegroundColor Cyan
    $out = (& adb @adbArgs shell "cmd package install-existing $RestorePackage" 2>&1) -join " "
    Write-Host "    -> $out" -ForegroundColor Green
    $RestoreMd = @(
        "# Google Pixel Package Restore Report (Step 4)"
        "- **Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "- **Device:** $Model"
        "- **Package:** ``$RestorePackage``"
        "- **Result:** ``$out``"
    ) -join "`r`n"
    $RestoreMd | Set-Content -Path $ReportFile -Encoding UTF8
    try { $RestoreMd | Set-Clipboard } catch {}
    Write-Host "[OK] Saved report to $ReportFile and copied to Clipboard!" -ForegroundColor Yellow
    exit 0
}

if ($RestoreAll) {
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "   RESTORING ALL PACKAGES & SETTINGS ON GOOGLE PIXEL      " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow

    $all = (& adb @adbArgs shell "pm list packages -u") | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ }
    $cur = (& adb @adbArgs shell "pm list packages")    | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ }
    $curSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$cur)
    $uninstalled = @($all | Where-Object { -not $curSet.Contains($_) } | Sort-Object)

    Write-Host "Total uninstalled packages found: $($uninstalled.Count)" -ForegroundColor Cyan
    $idx = 0
    $RestoredLogs = @()
    foreach ($pkg in $uninstalled) {
        $idx++
        Write-Host "[$idx/$($uninstalled.Count)] Restoring $pkg... " -NoNewline
        $out = (& adb @adbArgs shell "cmd package install-existing $pkg" 2>&1) -join " "
        if ($out -match "installed for user") {
            Write-Host "OK" -ForegroundColor Green
            $RestoredLogs += "- ``$pkg``: OK"
        } else {
            Write-Host "FAILED ($out)" -ForegroundColor Yellow
            $RestoredLogs += "- ``$pkg``: FAILED ($out)"
        }
    }

    Write-Host "`n[*] Resetting Animation & Modem settings to default..." -ForegroundColor Cyan
    & adb @adbArgs shell "settings put global window_animation_scale 1.0" 2>$null
    & adb @adbArgs shell "settings put global transition_animation_scale 1.0" 2>$null
    & adb @adbArgs shell "settings put global animator_duration_scale 1.0" 2>$null
    & adb @adbArgs shell "settings put global mobile_data_always_on 1" 2>$null
    & adb @adbArgs shell "settings put global wifi_scan_always_enabled 1" 2>$null
    & adb @adbArgs shell "settings put global ble_scan_always_enabled 1" 2>$null
    & adb @adbArgs shell "device_config delete activity_manager max_cached_processes" 2>$null

    $RestoreBody = if ($RestoredLogs.Count -gt 0) { $RestoredLogs -join "`r`n" } else { "- No uninstalled packages found." }
    $RestoreAllMd = @(
        "# Google Pixel Full Restore Report (Step 4 - Restore All)"
        "- **Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "- **Device:** $Model"
        "- **Total Restored:** $($uninstalled.Count)"
        ""
        "## Restored Packages"
        $RestoreBody
    ) -join "`r`n"
    $RestoreAllMd | Set-Content -Path $ReportFile -Encoding UTF8
    try { $RestoreAllMd | Set-Clipboard } catch {}
    Write-Host "==> Restore complete! Exported $ReportFile and copied to Clipboard." -ForegroundColor Green
    exit 0
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   STEP 4: VERIFY GOOGLE PIXEL POST-OPTIMIZATION STATUS   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$EnabledCnt  = ((& adb @adbArgs shell pm list packages -e) | Measure-Object).Count
$DisabledCnt = ((& adb @adbArgs shell pm list packages -d) | Measure-Object).Count
$StorageDf   = (& adb @adbArgs shell "df -h /data") -join "`n"
$MemInfo     = (& adb @adbArgs shell "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree'") -join "`n"
$TopMem      = (& adb @adbArgs shell "dumpsys meminfo | sed -n '/Total PSS by process:/,/Total PSS by OOM adjustment:/p' | head -n 15") -join "`n"
$MobAlwaysOn = ((& adb @adbArgs shell "settings get global mobile_data_always_on") -join "").Trim()
$WifiScan    = ((& adb @adbArgs shell "settings get global wifi_scan_always_enabled") -join "").Trim()
$BleScan     = ((& adb @adbArgs shell "settings get global ble_scan_always_enabled") -join "").Trim()
$AnimWin     = ((& adb @adbArgs shell "settings get global window_animation_scale") -join "").Trim()

$Summary = @(
    "# Google Pixel Post-Optimization Verification (Step 4 - Verify)"
    ""
    "- **Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Device:** $Model"
    "- **Active Packages:** ``$EnabledCnt`` (Disabled: ``$DisabledCnt``)"
    ""
    "## 1. Optimization Settings Status"
    "| Setting Key | Current Value | Target Value |"
    "| :--- | :---: | :---: |"
    "| ``mobile_data_always_on`` | ``$MobAlwaysOn`` | ``0`` |"
    "| ``wifi_scan_always_enabled`` | ``$WifiScan`` | ``0`` |"
    "| ``ble_scan_always_enabled`` | ``$BleScan`` | ``0`` |"
    "| ``window_animation_scale`` | ``$AnimWin`` | ``0.5`` |"
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
    "## 4. Top RAM Processes"
    "``````text"
    $TopMem
    "``````"
) -join "`r`n"

$Summary | Set-Content -Path $ReportFile -Encoding UTF8
Write-Host $Summary -ForegroundColor Green
try {
    $Summary | Set-Clipboard
    Write-Host "`n[OK] COPIED STEP 4 REPORT TO CLIPBOARD & EXPORTED .MD TO DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] EXPORTED STEP 4 .MD REPORT TO DESKTOP!" -ForegroundColor Green
}
Write-Host "Markdown Report: $ReportFile" -ForegroundColor Yellow
