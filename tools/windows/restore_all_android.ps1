<#
.SYNOPSIS
  Restores uninstalled system packages and resets Android optimizations on Windows.
  Prioritizes critical system overlays, Qualcomm/MTK drivers, and vendor services first.

.USAGE
  Restore all uninstalled packages:
    powershell -ExecutionPolicy Bypass -File .\restore_all_android.ps1
  Restore a single package:
    powershell -ExecutionPolicy Bypass -File .\restore_all_android.ps1 -Package com.miui.cloudbackup
#>

param(
    [string]$Package = "",
    [string]$Device = ""
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\adb_work\platform-tools\adb.exe") {
        $env:Path = "C:\adb_work\platform-tools;" + $env:Path
    } else {
        Write-Host "[!] Không tìm thấy adb.exe. Hãy chạy debloat_safe_android.ps1 trước hoặc cài platform-tools." -ForegroundColor Red
        exit 1
    }
}

$adbArgs = @()
if ($Device) { $adbArgs = @("-s", $Device) }

if ($Package) {
    Write-Host "[*] Đang khôi phục gói: $Package ..." -ForegroundColor Cyan
    $out = (& adb @adbArgs shell "cmd package install-existing $Package" 2>&1) -join " "
    Write-Host "    -> $out" -ForegroundColor Green
    exit 0
}

function Get-UninstalledPackages {
    $all = (& adb @adbArgs shell "pm list packages -u") | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ }
    $cur = (& adb @adbArgs shell "pm list packages")    | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ }
    $curSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$cur)
    return $all | Where-Object { -not $curSet.Contains($_) } | Sort-Object
}

$uninstalled = @(Get-UninstalledPackages)
Write-Host "Tổng số gói đã gỡ tìm thấy: $($uninstalled.Count)" -ForegroundColor Cyan
if ($uninstalled.Count -eq 0) {
    Write-Host "[+] Không có gói nào bị gỡ. Tất cả đã ở trạng thái nguyên bản!" -ForegroundColor Green
    exit 0
}

# Ưu tiên khôi phục các gói quan trọng trước (overlay, qualcomm, qti, xiaomi, samsung, google)
$priorityKeywords = @("overlay", "qualcomm", "qti", "xiaomi", "miui", "samsung", "google")
$sortedPkgs = $uninstalled | Sort-Object {
    $pkg = $_
    for ($i = 0; $i -lt $priorityKeywords.Count; $i++) {
        if ($pkg -match $priorityKeywords[$i]) { return $i }
    }
    return $priorityKeywords.Count
}

$idx = 0
foreach ($pkg in $sortedPkgs) {
    $idx++
    Write-Host "[$idx/$($sortedPkgs.Count)] Đang khôi phục $pkg... " -NoNewline
    $out = (& adb @adbArgs shell "cmd package install-existing $pkg" 2>&1) -join " "
    if ($out -match "installed for user") {
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "FAILED ($out)" -ForegroundColor Yellow
    }
}

Write-Host "`n[*] Đang đưa cài đặt Animation, Modem và Background Process Limit về mặc định..." -ForegroundColor Cyan
& adb @adbArgs shell "settings put global window_animation_scale 1.0" 2>$null
& adb @adbArgs shell "settings put global transition_animation_scale 1.0" 2>$null
& adb @adbArgs shell "settings put global animator_duration_scale 1.0" 2>$null
& adb @adbArgs shell "settings put global mobile_data_always_on 1" 2>$null
& adb @adbArgs shell "settings put global wifi_scan_always_enabled 1" 2>$null
& adb @adbArgs shell "settings put global ble_scan_always_enabled 1" 2>$null
& adb @adbArgs shell "device_config delete activity_manager max_cached_processes" 2>$null

$remaining = @(Get-UninstalledPackages)
Write-Host "`n==> Hoàn tất! Số gói chưa khôi phục còn lại: $($remaining.Count)" -ForegroundColor Green
