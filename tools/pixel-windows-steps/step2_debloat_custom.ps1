<#
.SYNOPSIS
  [STEP 2 - CUSTOM DEBLOAT FOR GOOGLE PIXEL]
  Run after reviewing Step 1 scan results.
  Supports preview mode (-DryRun), group filtering (-Group), and extra packages (-ExtraPackages).
  Strictly protects core Google Pixel features (Now Playing, eSIM, AICore, Camera, Launcher,
  Pixel Stand Dreamliner, OK Google Hotword).
  Exports .md report to Desktop AND copies to Clipboard.

.USAGE
  1. Preview packages that will be removed (no changes made):
     powershell -ExecutionPolicy Bypass -File .\step2_debloat_custom.ps1 -DryRun

  2. Remove all selected safe bloatware groups (Carrier + Telemetry + BloatApps):
     powershell -ExecutionPolicy Bypass -File .\step2_debloat_custom.ps1

  3. Remove additional specific packages chosen after Step 1:
     powershell -ExecutionPolicy Bypass -File .\step2_debloat_custom.ps1 -ExtraPackages "com.example.app1,com.example.app2"
#>

param(
    [ValidateSet("All", "Carrier", "Telemetry", "BloatApps", "CustomOnly")]
    [string]$Group = "All",
    [string]$ExtraPackages = "",
    [switch]$DryRun,
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
$ReportFile = Join-Path $DesktopDir "Pixel_${SafeModel}_Step2_Debloat.md"

# Strictly protected Google Pixel core packages (never allow accidental removal)
$ProtectedPixelPackages = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    "com.google.android.as",                     # Android System Intelligence (Now Playing, Live Caption, Overview Selection)
    "com.google.android.as.oss",                 # Private Compute Services
    "com.google.android.aicore",                 # Google AICore (Pixel AI)
    "com.google.android.euicc",                  # eSIM Manager on Pixel
    "com.google.android.ims",                    # Carrier Services (VoLTE / Wi-Fi Calling)
    "com.google.android.apps.nexuslauncher",     # Pixel Launcher
    "com.google.android.GoogleCamera",           # Pixel Camera
    "com.google.android.gms",                    # Google Play Services
    "com.android.vending",                       # Google Play Store
    "com.google.android.dialer",                 # Google Phone Dialer
    "com.google.android.apps.messaging",         # Google Messages
    "com.google.android.contacts",               # Google Contacts
    "com.google.android.apps.photos",            # Google Photos
    "com.google.android.apps.dreamliner",        # Pixel Stand Wireless Charger (Kept)
    "com.google.android.dreamlinerupdater",      # Pixel Stand Updater (Kept)
    "com.android.hotwordenrollment.okgoogle",    # OK Google Hotword (Kept)
    "com.android.hotwordenrollment.xgoogle"      # Hey Google Hotword (Kept)
))

# Group 1: Hidden US Carrier Bloatware in Pixel ROMs
$CarrierPackages = @(
    @{ Pkg = "com.verizon.obdm";                         Desc = "Verizon OBDM Device Management" },
    @{ Pkg = "com.verizon.obdm_permissions";             Desc = "Verizon OBDM Permissions" },
    @{ Pkg = "com.verizon.services";                     Desc = "Verizon Background Services" },
    @{ Pkg = "com.verizon.mips.services";                Desc = "My Verizon Services" },
    @{ Pkg = "com.verizon.llkagent";                     Desc = "Verizon LLK Agent" },
    @{ Pkg = "com.vzw.apnlib";                           Desc = "Verizon APN Library" },
    @{ Pkg = "com.customermobile.preload.vzw";           Desc = "Verizon Preload Agent" },
    @{ Pkg = "com.android.sdm.plugins.sprintdm";         Desc = "Sprint Carrier DM Plugin" },
    @{ Pkg = "com.android.sdm.plugins.usccdm";           Desc = "US Cellular Carrier DM Plugin" },
    @{ Pkg = "com.android.sdm.plugins.connmo";           Desc = "US Carrier SDM ConnMO Plugin" },
    @{ Pkg = "com.android.sdm.plugins.dcmo";             Desc = "US Carrier SDM DCMO Plugin" },
    @{ Pkg = "com.android.sdm.plugins.diagmon";          Desc = "US Carrier Diagnostic Monitor" },
    @{ Pkg = "com.android.omadm.service";                Desc = "OMA-DM Carrier Service" },
    @{ Pkg = "com.google.omadm.trigger";                 Desc = "US Carrier OMA-DM Trigger" },
    @{ Pkg = "com.google.android.apps.cbrsnetworkmonitor"; Desc = "US CBRS Band Network Monitor" },
    @{ Pkg = "com.google.android.apps.carrier.log";      Desc = "Carrier Background Logger" },
    @{ Pkg = "com.att.iqi";                              Desc = "AT&T Carrier IQ Telemetry" },
    @{ Pkg = "com.tmobile.pr.adapt";                     Desc = "T-Mobile Adapt Service" },
    @{ Pkg = "com.sprint.ms.smf.services";               Desc = "Sprint Carrier Services" },
    @{ Pkg = "com.sprint.ce.updater";                    Desc = "Sprint Carrier Updater" }
)

# Group 2: Google Advertising, Diagnostics & Internal Bug/Telemetry Services
$TelemetryPackages = @(
    @{ Pkg = "com.google.mainline.telemetry";                       Desc = "Google Mainline Telemetry" },
    @{ Pkg = "com.google.mainline.adservices";                      Desc = "Google Mainline AdServices" },
    @{ Pkg = "com.google.android.adservices.api";                   Desc = "Google AdServices API" },
    @{ Pkg = "com.google.android.ondevicepersonalization.services"; Desc = "On-Device Ad Personalization" },
    @{ Pkg = "com.google.android.federatedcompute";                 Desc = "Federated Compute Ad Training" },
    @{ Pkg = "com.google.android.feedback";                         Desc = "Google Feedback" },
    @{ Pkg = "com.android.traceur";                                 Desc = "System Tracing Dev Logger" },
    @{ Pkg = "com.google.android.apps.internal.betterbug";          Desc = "Google Internal BetterBug Reporter" },
    @{ Pkg = "com.google.SSRestartDetector";                        Desc = "Subsystem Restart Telemetry Detector" },
    @{ Pkg = "com.qualcomm.qti.devicestatisticsservice";            Desc = "Qualcomm Device Statistics Telemetry" },
    @{ Pkg = "com.google.android.apps.helprtc";                     Desc = "Pixel Support Video Share" },
    @{ Pkg = "com.google.android.apps.diagnosticstool";             Desc = "Pixel Diagnostics Tool" }
)

# Group 3: Redundant / Discontinued System Utilities & Selected Media Bloat
$BloatAppsPackages = @(
    @{ Pkg = "com.google.android.apps.podcasts";                    Desc = "Google Podcasts (Discontinued)" },
    @{ Pkg = "com.google.android.apps.restore";                     Desc = "Google Setup Restore" },
    @{ Pkg = "com.google.android.apps.pixelmigrate";                Desc = "Pixel Data Transfer Migrate Tool" },
    @{ Pkg = "com.google.android.apps.tips";                        Desc = "Pixel Tips" },
    @{ Pkg = "com.android.providers.partnerbookmarks";              Desc = "Partner Bookmarks" },
    @{ Pkg = "com.android.egg";                                     Desc = "Android Easter Egg" },
    @{ Pkg = "com.google.android.marvin.talkback";                  Desc = "TalkBack Accessibility" },
    @{ Pkg = "com.google.android.accessibility.switchaccess";       Desc = "Switch Access" },
    @{ Pkg = "com.google.android.accessibility.soundamplifier";     Desc = "Sound Amplifier" },
    @{ Pkg = "com.google.audio.hearing.visualization.accessibility.scribe"; Desc = "Live Transcribe" },
    @{ Pkg = "com.google.android.apps.magazines";                   Desc = "Google News / Magazines" },
    @{ Pkg = "com.google.android.videos";                           Desc = "Google TV / Play Movies" },
    @{ Pkg = "com.google.android.apps.youtube.music";               Desc = "YouTube Music" }
)

$TargetList = @()
if ($Group -eq "All" -or $Group -eq "Carrier")   { $TargetList += $CarrierPackages }
if ($Group -eq "All" -or $Group -eq "Telemetry") { $TargetList += $TelemetryPackages }
if ($Group -eq "All" -or $Group -eq "BloatApps") { $TargetList += $BloatAppsPackages }

if ($ExtraPackages) {
    $extras = $ExtraPackages -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($ep in $extras) {
        $TargetList += @{ Pkg = $ep; Desc = "User requested extra package" }
    }
}

$InstalledRaw = (& adb @adbArgs shell pm list packages -e) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ }
$InstalledSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$InstalledRaw)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   STEP 2: GOOGLE PIXEL DEBLOAT (Group: $Group)           " -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "   [DRY-RUN MODE: PREVIEW ONLY, NO CHANGES MADE]          " -ForegroundColor Yellow
}
Write-Host "==========================================================" -ForegroundColor Cyan

$RemovedCount = 0
$SkippedCount = 0
$ActionLogs   = @()

foreach ($item in $TargetList) {
    $pkg = $item.Pkg
    $desc = $item.Desc

    if ($ProtectedPixelPackages.Contains($pkg)) {
        Write-Host "[PROTECTED] $pkg - Core Pixel feature kept safe!" -ForegroundColor Magenta
        $ActionLogs += "| ``$pkg`` | **PROTECTED (KEPT)** | $desc |"
        continue
    }

    if (-not $InstalledSet.Contains($pkg)) {
        $SkippedCount++
        continue
    }

    if ($DryRun) {
        Write-Host "[WILL REMOVE] $pkg - $desc" -ForegroundColor Yellow
        $ActionLogs += "| ``$pkg`` | **WILL REMOVE (Dry-Run)** | $desc |"
        $RemovedCount++
    } else {
        $out = (& adb @adbArgs shell "pm uninstall -k --user 0 $pkg" 2>&1) -join " "
        if ($out -match "Success") {
            Write-Host "[REMOVED] $pkg - $desc" -ForegroundColor Green
            $ActionLogs += "| ``$pkg`` | **REMOVED (Success)** | $desc |"
            $RemovedCount++
        } else {
            Write-Host "[ERROR]   $pkg : $out" -ForegroundColor Red
            $ActionLogs += "| ``$pkg`` | **ERROR ($out)** | $desc |"
        }
    }
}

$ModeLabel  = if ($DryRun) { "Dry-Run (Preview)" } else { "Executed Uninstall" }
$ExtraLabel = if ($ExtraPackages) { "``$ExtraPackages``" } else { "None" }
$TableBody  = if ($ActionLogs.Count -gt 0) { $ActionLogs -join "`r`n" } else { "| *(No matching packages found on device)* | - | - |" }

$MdReport = @(
    "# Google Pixel Debloat Report (Step 2 - Debloat)"
    ""
    "- **Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Device:** $Model"
    "- **Mode:** $ModeLabel (Group: ``$Group``)"
    "- **Extra Packages:** $ExtraLabel"
    "- **Summary:** Processed **$RemovedCount packages** | Skipped **$SkippedCount not installed**."
    ""
    "## Package Action Details"
    "| Package ID | Status | Description |"
    "| :--- | :--- | :--- |"
    $TableBody
) -join "`r`n"

$MdReport | Set-Content -Path $ReportFile -Encoding UTF8
try {
    $MdReport | Set-Clipboard
    Write-Host "`n[OK] COPIED STEP 2 REPORT TO CLIPBOARD & EXPORTED .MD TO DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] EXPORTED STEP 2 .MD REPORT TO DESKTOP!" -ForegroundColor Green
}
Write-Host "Markdown Report: $ReportFile" -ForegroundColor Yellow
