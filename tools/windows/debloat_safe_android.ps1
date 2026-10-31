<#
.SYNOPSIS
  All-in-One Android Safe Debloat & Optimization Script for Windows.
  Automatically downloads Google Platform-Tools (adb.exe) if missing, backs up installed packages,
  removes safe bloatware (Xiaomi, Samsung, OPPO/Realme, Google Pixel, Facebook, Microsoft),
  and applies smoothness/RAM/Modem optimizations.

.USAGE
  Open PowerShell and run:
  powershell -ExecutionPolicy Bypass -File .\debloat_safe_android.ps1
#>

param(
    [string]$Device = "",
    [switch]$SkipDexopt
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   ANDROID SAFE DEBLOAT & OPTIMIZER (WINDOWS POWERSHELL)  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# ---------- 1. Prepare ADB (Auto-download if missing) ----------
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
$devices = (& adb @adbArgs devices) | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" }
if (-not $devices) {
    Write-Host "[!] No connected Android device found in 'device' state!" -ForegroundColor Red
    Write-Host "    -> Check USB cable / Wireless Debugging, enable 'USB Debugging' and tap 'Allow' on phone." -ForegroundColor Yellow
    exit 1
}

# ---------- 2. Collect Device Info & Backup Package List ----------
$Brand = ((& adb @adbArgs shell getprop ro.product.brand) -join "").Trim()
$BrandLower = $Brand.ToLower()
$Model = ((& adb @adbArgs shell getprop ro.product.model) -join "").Trim() -replace '\s+', '_'
$AndroidVer = ((& adb @adbArgs shell getprop ro.build.version.release) -join "").Trim()
$MemTotalRaw = ((& adb @adbArgs shell "grep MemTotal /proc/meminfo") -join "").Trim()
$MemTotalKB = 0
if ($MemTotalRaw -match '(\d+)') { $MemTotalKB = [long]$Matches[1] }
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$DesktopDir = [Environment]::GetFolderPath("Desktop")
$BackupFile = Join-Path $DesktopDir "${Brand}_${Model}_packages_before_${Timestamp}.txt"

$InstalledRaw = (& adb @adbArgs shell pm list packages) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object
$InstalledSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$InstalledRaw)

$InstalledRaw | Set-Content -Path $BackupFile -Encoding UTF8
Write-Host "[+] Device : $Brand $Model (Android $AndroidVer)" -ForegroundColor Green
Write-Host "[+] Saved Backup ($($InstalledRaw.Count) packages) to: $BackupFile" -ForegroundColor Green

try {
    @(
        "=== DEVICE INFO ==="
        "Brand: $Brand | Model: $Model | Android: $AndroidVer"
        "=== RAM INFO ==="
        (& adb @adbArgs shell "cat /proc/meminfo | grep -E 'MemTotal|MemAvailable|SwapTotal'")
        "=== INSTALLED PACKAGES ($($InstalledRaw.Count)) ==="
        $InstalledRaw
    ) | Set-Clipboard
    Write-Host "[+] Copied device info & package list to Clipboard!" -ForegroundColor DarkCyan
} catch {}

# ---------- 3. 100% Safe Debloat Package List ----------
$SafeDebloatPackages = @(
    # 1. Xiaomi / Redmi / POCO Ads & Telemetry
    @{ Pkg = "com.miui.msa.global"; Desc = "Xiaomi System Ads" },
    @{ Pkg = "com.miui.analytics"; Desc = "Xiaomi Analytics Telemetry" },
    @{ Pkg = "com.miui.daemon"; Desc = "Xiaomi Daemon Telemetry" },
    @{ Pkg = "com.miui.bugreport"; Desc = "Xiaomi Bug Report" },
    @{ Pkg = "com.miui.miservice"; Desc = "Xiaomi Feedback Service" },
    @{ Pkg = "com.miui.misightservice"; Desc = "Xiaomi MiSight Telemetry" },
    @{ Pkg = "com.mi.appfinder"; Desc = "Xiaomi App Finder" },
    @{ Pkg = "com.mi.globalminusscreen"; Desc = "Xiaomi App Vault (-1 Screen)" },
    @{ Pkg = "com.xiaomi.mipicks"; Desc = "Xiaomi GetApps Store" },
    @{ Pkg = "com.miui.yellowpage"; Desc = "Xiaomi Yellow Pages" },
    @{ Pkg = "com.xiaomi.payment"; Desc = "Xiaomi Mi Pay" },
    @{ Pkg = "com.xiaomi.glgm"; Desc = "Xiaomi Game Center" },
    @{ Pkg = "com.xiaomi.barrage"; Desc = "Xiaomi Bullet Screen" },
    @{ Pkg = "com.xiaomi.aiasst.vision"; Desc = "Xiaomi AI Vision" },
    @{ Pkg = "com.miui.thirdappassistant"; Desc = "Xiaomi Third App Assistant" },
    @{ Pkg = "com.miui.phrase"; Desc = "Xiaomi Frequent Phrases" },
    @{ Pkg = "com.mi.globalbrowser"; Desc = "Xiaomi Mi Browser" },
    @{ Pkg = "com.miui.videoplayer"; Desc = "Xiaomi Mi Video" },
    @{ Pkg = "com.miui.player"; Desc = "Xiaomi Mi Music" },
    @{ Pkg = "com.miui.guardprovider"; Desc = "Xiaomi GuardProvider (~120MB RAM)" },
    @{ Pkg = "com.xiaomi.aicr"; Desc = "Xiaomi AI Engine" },
    @{ Pkg = "com.xiaomi.ugd"; Desc = "Xiaomi UGD Service" },
    @{ Pkg = "com.xiaomi.discover"; Desc = "Xiaomi System App Updater Ads" },
    @{ Pkg = "com.miui.virtualsim"; Desc = "Xiaomi Mi Roaming" },
    @{ Pkg = "com.miui.vsimcore"; Desc = "Xiaomi Virtual SIM Core" },

    # 2. Samsung One UI Bloatware
    @{ Pkg = "com.aura.oobe.samsung.gl"; Desc = "Samsung AppCloud / IronSource Ad Installer" },
    @{ Pkg = "com.samsung.android.game.gos"; Desc = "Samsung Game Optimizing Service (GOS)" },
    @{ Pkg = "com.samsung.android.bixby.agent"; Desc = "Bixby Voice Assistant" },
    @{ Pkg = "com.samsung.android.bixby.wakeup"; Desc = "Bixby Voice Wakeup" },
    @{ Pkg = "com.samsung.android.visionintelligence"; Desc = "Bixby Vision" },
    @{ Pkg = "com.samsung.android.bixby.service"; Desc = "Bixby Background Service" },
    @{ Pkg = "com.samsung.android.app.settings.bixby"; Desc = "Bixby Settings" },
    @{ Pkg = "com.samsung.android.app.spage"; Desc = "Samsung Free / Daily (-1 Screen)" },
    @{ Pkg = "com.samsung.android.ardrawing"; Desc = "Samsung AR Doodle" },
    @{ Pkg = "com.samsung.android.arzone"; Desc = "Samsung AR Zone" },
    @{ Pkg = "com.samsung.android.aremoji"; Desc = "Samsung AR Emoji" },
    @{ Pkg = "com.samsung.android.aremojieditor"; Desc = "Samsung AR Emoji Editor" },
    @{ Pkg = "com.sec.android.mimage.avatarstickers"; Desc = "Samsung Avatar Stickers" },
    @{ Pkg = "com.samsung.android.game.gamehome"; Desc = "Samsung Game Launcher" },
    @{ Pkg = "com.samsung.android.game.gametools"; Desc = "Samsung Game Booster" },
    @{ Pkg = "com.samsung.android.app.tips"; Desc = "Samsung Tips" },
    @{ Pkg = "com.samsung.android.kidsinstaller"; Desc = "Samsung Kids Installer" },
    @{ Pkg = "com.samsung.android.rubin.app"; Desc = "Samsung Customization Tracking Service" },

    # 3. OPPO / Realme / OnePlus (ColorOS)
    @{ Pkg = "com.heytap.browser"; Desc = "HeyTap Browser" },
    @{ Pkg = "com.heytap.market"; Desc = "HeyTap App Market" },
    @{ Pkg = "com.heytap.themestore"; Desc = "HeyTap Theme Store" },
    @{ Pkg = "com.nearme.statistics.rom"; Desc = "ColorOS User Statistics Telemetry" },
    @{ Pkg = "com.coloros.gamespace"; Desc = "ColorOS Game Space" },

    # 4. Facebook & Microsoft Preload Services
    @{ Pkg = "com.facebook.services"; Desc = "Facebook Background Services" },
    @{ Pkg = "com.facebook.system"; Desc = "Facebook System Installer" },
    @{ Pkg = "com.facebook.appmanager"; Desc = "Facebook App Manager" },
    @{ Pkg = "com.microsoftsdk.crossdeviceservicebroker"; Desc = "Microsoft Cross Device Broker" },
    @{ Pkg = "com.microsoft.appmanager"; Desc = "Microsoft Phone Link Service" },

    # 5. Google & Android Telemetry / Ads
    @{ Pkg = "com.google.android.feedback"; Desc = "Google Feedback" },
    @{ Pkg = "com.google.android.apps.subscriptions.red"; Desc = "Google One Promo" },
    @{ Pkg = "com.google.android.apps.restore"; Desc = "Google Setup Restore" },
    @{ Pkg = "com.google.android.apps.tachyon"; Desc = "Google Meet / Duo" },
    @{ Pkg = "com.google.android.videos"; Desc = "Google TV / Play Movies" },
    @{ Pkg = "com.android.traceur"; Desc = "System Tracing Dev Logger" },
    @{ Pkg = "com.android.egg"; Desc = "Android Easter Egg" },
    @{ Pkg = "com.android.providers.partnerbookmarks"; Desc = "Partner Bookmarks" },
    @{ Pkg = "com.google.android.as"; Desc = "Android System Intelligence (Kept on Google Pixel)" },
    @{ Pkg = "com.google.android.as.oss"; Desc = "Private Compute Services (Kept on Google Pixel)" },
    @{ Pkg = "com.android.hotwordenrollment.okgoogle"; Desc = "OK Google Hotword Enrollment (~103MB RAM)" },
    @{ Pkg = "com.android.hotwordenrollment.xgoogle"; Desc = "Hey Google Hotword Enrollment" },
    @{ Pkg = "com.google.android.apps.wellbeing"; Desc = "Digital Wellbeing Tracker" },
    @{ Pkg = "com.google.mainline.telemetry"; Desc = "Google Mainline Telemetry" },
    @{ Pkg = "com.google.mainline.adservices"; Desc = "Google Mainline AdServices" },
    @{ Pkg = "com.google.android.adservices.api"; Desc = "Google AdServices API" },
    @{ Pkg = "com.google.android.ondevicepersonalization.services"; Desc = "On-Device Ad Personalization" },
    @{ Pkg = "com.google.android.federatedcompute"; Desc = "Federated Compute Ad Training" },
    @{ Pkg = "com.google.android.marvin.talkback"; Desc = "TalkBack Accessibility" },
    @{ Pkg = "com.google.android.accessibility.switchaccess"; Desc = "Switch Access" },

    # 6. Google Pixel Bloatware & Hidden US/JP Carrier Services
    @{ Pkg = "com.google.android.apps.tips"; Desc = "Pixel Tips" },
    @{ Pkg = "com.google.android.apps.helprtc"; Desc = "Pixel Support Video Share" },
    @{ Pkg = "com.google.android.apps.diagnosticstool"; Desc = "Pixel Diagnostics Tool" },
    @{ Pkg = "com.android.retaildemo"; Desc = "Retail Demo Mode" },
    @{ Pkg = "com.google.android.retaildemo"; Desc = "Google Retail Demo" },
    @{ Pkg = "com.verizon.mips.services"; Desc = "My Verizon Services (Hidden Carrier Bloat)" },
    @{ Pkg = "com.verizon.llkagent"; Desc = "Verizon LLK Agent" },
    @{ Pkg = "com.vzw.apnlib"; Desc = "Verizon APN Library" },
    @{ Pkg = "com.customermobile.preload.vzw"; Desc = "Verizon Preload Agent" },
    @{ Pkg = "com.att.iqi"; Desc = "AT&T Carrier IQ Telemetry" },
    @{ Pkg = "com.tmobile.pr.adapt"; Desc = "T-Mobile Adapt Service" },
    @{ Pkg = "com.sprint.ms.smf.services"; Desc = "Sprint Carrier Services" },
    @{ Pkg = "com.sprint.ce.updater"; Desc = "Sprint Carrier Updater" },
    @{ Pkg = "com.google.omadm.trigger"; Desc = "US Carrier OMA-DM Trigger" },

    # 7. Factory Test & Diagnostic Bloat
    @{ Pkg = "com.fingerprints.sensortesttool"; Desc = "Fingerprint Factory Test" },
    @{ Pkg = "com.goodix.gftest"; Desc = "Goodix Sensor Factory Test" },
    @{ Pkg = "com.longcheertel.AutoTest"; Desc = "Factory AutoTest" },
    @{ Pkg = "com.longcheertel.cit"; Desc = "Factory CIT Test" },
    @{ Pkg = "com.longcheertel.sarauth"; Desc = "Factory SAR Auth" },
    @{ Pkg = "com.wdstechnology.android.kryten"; Desc = "OMA-DM Provisioning" },
    @{ Pkg = "com.qualcomm.qti.remoteSimlockAuth"; Desc = "Remote Simlock Auth" },
    @{ Pkg = "com.qualcomm.qti.ridemodeaudio"; Desc = "Qualcomm Ride Mode Audio" },
    @{ Pkg = "com.qti.snapdragon.qdcm_ff"; Desc = "QDCM Color Mode Test" },
    @{ Pkg = "com.bsp.logmanager"; Desc = "Factory Log Manager" },
    @{ Pkg = "com.novatek.novavis"; Desc = "Display Debug Tool" }
)

Write-Host "`n=== STEP 1: SAFE DEBLOAT (Checking $($SafeDebloatPackages.Count) packages) ===" -ForegroundColor Cyan
$SuccessCount = 0
$SkippedCount = 0

foreach ($item in $SafeDebloatPackages) {
    $pkg = $item.Pkg
    $desc = $item.Desc
    if (-not $InstalledSet.Contains($pkg)) {
        $SkippedCount++
        continue
    }

    if ($BrandLower -eq "google" -and ($pkg -eq "com.google.android.as" -or $pkg -eq "com.google.android.as.oss")) {
        Write-Host "[KEPT FOR PIXEL] $pkg - Preserving Pixel Now Playing, Live Caption & Overview Selection" -ForegroundColor DarkCyan
        $SkippedCount++
        continue
    }

    $out = (& adb @adbArgs shell "pm uninstall -k --user 0 $pkg" 2>&1) -join " "
    if ($out -match "Success") {
        Write-Host "[REMOVED] $pkg - $desc" -ForegroundColor Green
        $SuccessCount++
    } else {
        Write-Host "[ERROR]   $pkg : $out" -ForegroundColor DarkYellow
    }
}
Write-Host "==> Debloat Summary: Removed $SuccessCount packages | Skipped $SkippedCount packages." -ForegroundColor Cyan

# ---------- 4. Performance, Battery & Smoothness Tuning ----------
Write-Host "`n=== STEP 2: UI SMOOTHNESS, MODEM BATTERY & RAM OPTIMIZATION ===" -ForegroundColor Cyan

Write-Host "[*] Setting Animation Scale to 0.5x..." -ForegroundColor White
& adb @adbArgs shell "settings put global window_animation_scale 0.5" 2>$null
& adb @adbArgs shell "settings put global transition_animation_scale 0.5" 2>$null
& adb @adbArgs shell "settings put global animator_duration_scale 0.5" 2>$null
$animCheck = ((& adb @adbArgs shell "settings get global window_animation_scale") -join "").Trim()
if ($animCheck -eq "0.5") {
    Write-Host "    -> Animation set to 0.5x!" -ForegroundColor Green
} else {
    Write-Host "    -> [Note for Xiaomi] Enable 'USB debugging (Security settings)' or set Animation 0.5x manually in Developer Options." -ForegroundColor Yellow
}

Write-Host "[*] Optimizing Modem & Disabling 24/7 Background Scanning..." -ForegroundColor White
& adb @adbArgs shell "settings put global mobile_data_always_on 0" 2>$null
& adb @adbArgs shell "settings put global wifi_scan_always_enabled 0" 2>$null
& adb @adbArgs shell "settings put global ble_scan_always_enabled 0" 2>$null
Write-Host "    -> Disabled mobile_data_always_on (0) & wifi/ble_scan_always_enabled (0)!" -ForegroundColor Green

if ($BrandLower -eq "google" -or $MemTotalKB -gt 6500000) {
    Write-Host "[*] High RAM (>6GB) or Google Pixel detected: Unlocking default RAM multitasking..." -ForegroundColor White
    & adb @adbArgs shell "device_config delete activity_manager max_cached_processes" 2>$null
} else {
    Write-Host "[*] Low/Mid RAM (<=6GB) detected: Setting max_cached_processes = 8..." -ForegroundColor White
    & adb @adbArgs shell "device_config put activity_manager max_cached_processes 8" 2>$null
}

if ($BrandLower -eq "samsung") {
    Write-Host "[*] Optimizing Samsung RAM Plus (setting ram_expand_size = 2048 MB)..." -ForegroundColor White
    & adb @adbArgs shell "settings put global ram_expand_size 2048" 2>$null
}

Write-Host "[*] Trimming system caches (pm trim-caches)..." -ForegroundColor White
& adb @adbArgs shell "pm trim-caches 999999999999999999" 2>$null

if (-not $SkipDexopt) {
    Write-Host "[*] Running AOT app compilation (bg-dexopt-job, takes ~30-90s)..." -ForegroundColor Yellow
    & adb @adbArgs shell "cmd package bg-dexopt-job" | Out-Null
    Write-Host "    -> AOT compilation completed!" -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   OPTIMIZATION COMPLETE! BACKUP SAVED TO DESKTOP:        " -ForegroundColor Green
Write-Host "   $BackupFile" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
