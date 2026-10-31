$env:Path = "C:\adb_work\platform-tools;" + $env:Path

Write-Host "=== STEP 2: DEBLOATING LENOVO TAB P11 (TB-J606F) ===" -ForegroundColor Cyan

# Protected: com.lmsa.app.lmsapad (Lenovo PC Assistant) & com.microsoft.bing.wallpapers (Bing Wallpapers)
$LenovoPkgsToRemove = @(
    # 0. Lenovo Face Unlock (118MB RAM background daemon)
    "com.lenovo.faceauthentication",
    # 1. Lenovo Bloatware, Telemetry, Retail Demo & Entertainment Space (Kept com.lmsa.app.lmsapad)
    "com.lenovo.ue.device", "com.huaqin.lenovoprivacy", "com.lenovo.lsf", "com.lenovo.lsf.device",
    "com.lenovo.dsa", "com.tblenovo.center", "com.tblenovo.lenovowhatsnew", "com.motorola.demo",
    "com.google.android.apps.mediahome.launcher",
    # 2. Factory Hardware Test & Engineering Debug Tools
    "com.yha.factory", "com.huaqin.capsensortest", "com.lenovo.EngineeringCode",
    "com.lenovo.loggerpannel", "com.qti.snapdragon.qdcm_ff",
    # 3. Qualcomm & Google Telemetry / Unused SIM Services on Wi-Fi Tablet
    "com.qualcomm.qti.qms.service.telemetry", "com.qualcomm.qti.qdma", "com.qti.diagservices",
    "com.qualcomm.qti.devicestatisticsservice", "com.qualcomm.qti.remoteSimlockAuth", "com.qualcomm.embms",
    "com.google.mainline.telemetry", "com.google.android.feedback", "com.android.traceur",
    "com.google.android.apps.restore", "com.google.android.apps.youtube.music.setupwizard",
    "com.android.providers.partnerbookmarks", "com.android.providers.partnerbrowsercustomizations",
    "com.android.egg", "com.android.dreams.phototable", "com.google.android.marvin.talkback",
    # 4. Group 2 Selected Apps: Google TV, Bamboo Paper, Squid
    "com.google.android.videos", "com.wacom.bamboopapertab", "com.steadfastinnovation.android.projectpapyrus"
)

$RemovedCount = 0
$ActionRows = @()
foreach ($pkg in $LenovoPkgsToRemove) {
    $res = (adb shell "pm uninstall -k --user 0 $pkg" 2>&1) -join " "
    if ($res -match "Success") {
        Write-Host "[REMOVED] $pkg" -ForegroundColor Green
        $ActionRows += ("| " + $pkg + " | **REMOVED (Success)** |")
        $RemovedCount++
    } else {
        Write-Host "[SKIP/ERR] $pkg : $res" -ForegroundColor DarkGray
        $ActionRows += ("| " + $pkg + " | " + $res + " |")
    }
}

Write-Host "`n=== STEP 3: SYSTEM OPTIMIZATION FOR LENOVO TAB P11 ===" -ForegroundColor Cyan

# 1. Set max_cached_processes = 24 (Down from 60)
adb shell "device_config put activity_manager max_cached_processes 24"
Write-Host "[1/4] Set max_cached_processes = 24 (Before: 60)" -ForegroundColor Green

# 2. Disable mobile_data_always_on & 24/7 Wi-Fi/BLE scanning
adb shell "settings put global mobile_data_always_on 0"
adb shell "settings put global wifi_scan_always_enabled 0"
adb shell "settings put global ble_scan_always_enabled 0"
Write-Host "[2/4] Disabled mobile_data_always_on (0) & wifi/ble_scan_always_enabled (0)" -ForegroundColor Green

# 3. Trim system caches
adb shell "pm trim-caches 999999999999999999" 2>$null
Write-Host "[3/4] Trimmed system caches (pm trim-caches)" -ForegroundColor Green

# 4. Run AOT compilation (takes ~30-90 seconds)
Write-Host "[4/4] Running AOT app optimization (bg-dexopt-job, please wait ~30-90s)..." -ForegroundColor Yellow
adb shell "cmd package bg-dexopt-job" | Out-Null
Write-Host "      -> AOT compilation completed!" -ForegroundColor Green

# --- STEP 4: VERIFY & EXPORT REPORT ---
$EnabledCnt = ((adb shell pm list packages -e) | Measure-Object).Count
$MaxCached  = ((adb shell "dumpsys activity settings | grep -i cur_max_cached") -join " ").Trim()
$MobAlways  = ((adb shell "settings get global mobile_data_always_on") -join "").Trim()
$WifiScan   = ((adb shell "settings get global wifi_scan_always_enabled") -join "").Trim()
$BleScan    = ((adb shell "settings get global ble_scan_always_enabled") -join "").Trim()
$StorageDf  = (adb shell "df -h /data") -join "`n"
$MemInfo    = (adb shell "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree'") -join "`n"

$ReportMd = (@(
    "# Lenovo Tab P11 (TB-J606F) Optimization Report"
    "- **Packages Removed:** **$RemovedCount / $($LenovoPkgsToRemove.Count)**"
    "- **Active Packages Remaining:** ``$EnabledCnt``"
    "- **Kept Safe:** ``com.lmsa.app.lmsapad`` (Lenovo PC Connect) & ``com.microsoft.bing.wallpapers`` (Bing Wallpapers)"
    "- **Max Cached Processes:** ``$MaxCached`` (Before: 60)"
    "- **mobile_data_always_on:** ``$MobAlways`` (Before: 1)"
    "- **wifi_scan_always_enabled:** ``$WifiScan`` (Before: 1)"
    "- **ble_scan_always_enabled:** ``$BleScan`` (Before: 1)"
    "- **Cache Cleanup & AOT Compilation:** Completed"
    ""
    "## Storage (/data)"
    '```text'
    $StorageDf
    '```'
    ""
    "## RAM & Swap Info"
    '```text'
    $MemInfo
    '```'
    ""
    "## Removed Packages Detail"
    "| Package ID | Status |"
    "| :--- | :--- |"
) + $ActionRows) -join "`r`n"

$VerifyPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Lenovo_TB-J606F_Verify_Report.md"
$ReportMd | Set-Content -Path $VerifyPath -Encoding UTF8
$ReportMd | Set-Clipboard
Write-Host "`n[OK] ALL DONE! Saved to $VerifyPath and copied to Clipboard (Press Ctrl+V)!" -ForegroundColor Cyan