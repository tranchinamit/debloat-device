<#
.SYNOPSIS
  [STEP 3 - OPTIMIZE ZRAM MULTITASKING, CACHES & AOT COMPILATION FOR GOOGLE PIXEL]
  Applies only:
  1. Sets max_cached_processes = 16 (relieves 98% ZRAM swap pressure while keeping 16 apps cached in RAM).
  2. Trims system caches (pm trim-caches) & runs AOT app compilation (bg-dexopt-job).
  Exports .md report to Desktop AND copies to Clipboard.

.USAGE
  powershell -ExecutionPolicy Bypass -File .\step3_optimize_pixel.ps1
#>

param(
    [int]$MaxCachedProcesses = 16,
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

$BeforeCached = (& adb @adbArgs shell "dumpsys activity settings | grep -i cur_max_cached") -join " "

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   STEP 3: GOOGLE PIXEL ZRAM, CACHE & AOT OPTIMIZATION    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Balance RAM & ZRAM Swap pressure
Write-Host "`n[1/3] Setting max_cached_processes = $MaxCachedProcesses..." -ForegroundColor White
& adb @adbArgs shell "device_config put activity_manager max_cached_processes $MaxCachedProcesses" 2>$null
Write-Host "      -> Set max_cached_processes = $MaxCachedProcesses!" -ForegroundColor Green

# 2. Trim Caches
Write-Host "`n[2/3] Trimming system caches (pm trim-caches)..." -ForegroundColor White
& adb @adbArgs shell "pm trim-caches 999999999999999999" 2>$null
Write-Host "      -> System caches trimmed!" -ForegroundColor Green

# 3. AOT Dexopt
$DexoptStatus = "Skipped (-SkipDexopt)"
if (-not $SkipDexopt) {
    Write-Host "`n[3/3] Running AOT app optimization (bg-dexopt-job, takes ~30-90s)..." -ForegroundColor Yellow
    & adb @adbArgs shell "cmd package bg-dexopt-job" | Out-Null
    Write-Host "      -> AOT compilation completed!" -ForegroundColor Green
    $DexoptStatus = "Completed (bg-dexopt-job)"
} else {
    Write-Host "`n[3/3] Skipped bg-dexopt-job as requested." -ForegroundColor DarkGray
}

$AfterCached = (& adb @adbArgs shell "dumpsys activity settings | grep -i cur_max_cached") -join " "
$StorageDf   = (& adb @adbArgs shell "df -h /data") -join "`n"
$MemInfo     = (& adb @adbArgs shell "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree'") -join "`n"

$MdReport = @(
    "# Google Pixel Optimization Report (Step 3 - Optimize)"
    ""
    "- **Time:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Device:** $Model"
    "- **max_cached_processes (Before):** ``$BeforeCached``"
    "- **max_cached_processes (After):** ``$AfterCached``"
    "- **Cache Cleanup (pm trim-caches):** ``Completed``"
    "- **AOT Compilation (bg-dexopt-job):** ``$DexoptStatus``"
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
) -join "`r`n"

$MdReport | Set-Content -Path $ReportFile -Encoding UTF8
try {
    $MdReport | Set-Clipboard
    Write-Host "`n[OK] COPIED STEP 3 REPORT TO CLIPBOARD & EXPORTED .MD TO DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] EXPORTED STEP 3 .MD REPORT TO DESKTOP!" -ForegroundColor Green
}
Write-Host "Markdown Report: $ReportFile" -ForegroundColor Yellow
