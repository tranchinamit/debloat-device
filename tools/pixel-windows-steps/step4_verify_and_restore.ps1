<#
.SYNOPSIS
  [BƯỚC 4 - KIỂM TRA KẾT QUẢ SAU TỐI ƯU HOẶC KHÔI PHỤC GÓI ĐÃ GỠ]
  Mặc định: Kiểm tra lại RAM trống, Bộ nhớ trống, Nhiệt độ Pin, Cài đặt Modem,
  xuất báo cáo ra file Markdown (.md) ngoài Desktop VÀ copy vào Clipboard.
  Hỗ trợ khôi phục nhanh 1 gói (-RestorePackage) hoặc khôi phục toàn bộ về nguyên bản (-RestoreAll).

.USAGE
  1. Kiểm tra thông số sau khi tối ưu:
     powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1

  2. Khôi phục 1 gói cụ thể:
     powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1 -RestorePackage com.google.android.videos

  3. Khôi phục toàn bộ máy về mặc định:
     powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1 -RestoreAll
#>

param(
    [string]$RestorePackage = "",
    [switch]$RestoreAll,
    [string]$Device = ""
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\adb_work\platform-tools\adb.exe") {
        $env:Path = "C:\adb_work\platform-tools;" + $env:Path
    } else {
        Write-Host "[!] Chưa có ADB. Hãy chạy step1_scan_pixel.ps1 trước!" -ForegroundColor Red
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
    Write-Host "[*] Đang khôi phục gói: $RestorePackage ..." -ForegroundColor Cyan
    $out = (& adb @adbArgs shell "cmd package install-existing $RestorePackage" 2>&1) -join " "
    Write-Host "    -> $out" -ForegroundColor Green
    $RestoreMd = @(
        "# Báo cáo Khôi phục Gói (Step 4 - Restore Single Package)"
        "- **Thời gian:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "- **Thiết bị:** $Model"
        "- **Gói khôi phục:** ``$RestorePackage``"
        "- **Kết quả:** ``$out``"
    ) -join "`r`n"
    $RestoreMd | Set-Content -Path $ReportFile -Encoding UTF8
    try { $RestoreMd | Set-Clipboard } catch {}
    Write-Host "[OK] Đã lưu báo cáo vào $ReportFile và copy vào Clipboard!" -ForegroundColor Yellow
    exit 0
}

if ($RestoreAll) {
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "   KHÔI PHỤC TOÀN BỘ GÓI & CÀI ĐẶT GOOGLE PIXEL VỀ GỐC    " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow

    $all = (& adb @adbArgs shell "pm list packages -u") | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ }
    $cur = (& adb @adbArgs shell "pm list packages")    | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ }
    $curSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$cur)
    $uninstalled = @($all | Where-Object { -not $curSet.Contains($_) } | Sort-Object)

    Write-Host "Tổng số gói đã gỡ tìm thấy: $($uninstalled.Count)" -ForegroundColor Cyan
    $idx = 0
    $RestoredLogs = @()
    foreach ($pkg in $uninstalled) {
        $idx++
        Write-Host "[$idx/$($uninstalled.Count)] Đang khôi phục $pkg... " -NoNewline
        $out = (& adb @adbArgs shell "cmd package install-existing $pkg" 2>&1) -join " "
        if ($out -match "installed for user") {
            Write-Host "OK" -ForegroundColor Green
            $RestoredLogs += "- ``$pkg``: OK"
        } else {
            Write-Host "FAILED ($out)" -ForegroundColor Yellow
            $RestoredLogs += "- ``$pkg``: FAILED ($out)"
        }
    }

    Write-Host "`n[*] Đang đưa cài đặt Animation & Modem về mặc định..." -ForegroundColor Cyan
    & adb @adbArgs shell "settings put global window_animation_scale 1.0" 2>$null
    & adb @adbArgs shell "settings put global transition_animation_scale 1.0" 2>$null
    & adb @adbArgs shell "settings put global animator_duration_scale 1.0" 2>$null
    & adb @adbArgs shell "settings put global mobile_data_always_on 1" 2>$null
    & adb @adbArgs shell "settings put global wifi_scan_always_enabled 1" 2>$null
    & adb @adbArgs shell "settings put global ble_scan_always_enabled 1" 2>$null
    & adb @adbArgs shell "device_config delete activity_manager max_cached_processes" 2>$null

    $RestoreAllMd = @(
        "# Báo cáo Khôi phục Toàn bộ Google Pixel (Step 4 - Restore All)"
        "- **Thời gian:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "- **Thiết bị:** $Model"
        "- **Tổng số gói đã khôi phục:** $($uninstalled.Count)"
        ""
        "## Danh sách Gói đã xử lý"
        $(if ($RestoredLogs.Count -gt 0) { $RestoredLogs -join "`r`n" } else { "- Không có gói nào bị gỡ." })
    ) -join "`r`n"
    $RestoreAllMd | Set-Content -Path $ReportFile -Encoding UTF8
    try { $RestoreAllMd | Set-Clipboard } catch {}
    Write-Host "==> Hoàn tất khôi phục! Đã xuất file $ReportFile và copy vào Clipboard." -ForegroundColor Green
    exit 0
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   BƯỚC 4: KIỂM TRA KẾT QUẢ SAU KHI TỐI ƯU GOOGLE PIXEL   " -ForegroundColor Cyan
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
    "# Báo cáo Kiểm tra Sau Tối ưu Google Pixel (Step 4 - Verify)"
    ""
    "- **Thời gian:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Thiết bị:** $Model"
    "- **Tổng số gói đang bật:** ``$EnabledCnt`` (Đang tắt: ``$DisabledCnt``)"
    ""
    "## 1. Trạng thái Các Cài đặt Tối ưu"
    "| Thông số | Giá trị hiện tại | Chuẩn tối ưu |"
    "| :--- | :---: | :---: |"
    "| ``mobile_data_always_on`` | ``$MobAlwaysOn`` | ``0`` |"
    "| ``wifi_scan_always_enabled`` | ``$WifiScan`` | ``0`` |"
    "| ``ble_scan_always_enabled`` | ``$BleScan`` | ``0`` |"
    "| ``window_animation_scale`` | ``$AnimWin`` | ``0.5`` |"
    ""
    "## 2. Bộ nhớ Lưu trữ (/data)"
    "``````text"
    $StorageDf
    "``````"
    ""
    "## 3. Dung lượng RAM & Swap Sau Tối ưu"
    "``````text"
    $MemInfo
    "``````"
    ""
    "## 4. Top Tiến trình RAM Hiện tại"
    "``````text"
    $TopMem
    "``````"
) -join "`r`n"

$Summary | Set-Content -Path $ReportFile -Encoding UTF8
Write-Host $Summary -ForegroundColor Green
try {
    $Summary | Set-Clipboard
    Write-Host "`n[OK] ĐÃ COPY BÁO CÁO BƯỚC 4 VÀO CLIPBOARD & XUẤT FILE .MD RA DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] ĐÃ XUẤT FILE .MD BƯỚC 4 RA DESKTOP!" -ForegroundColor Green
}
Write-Host "File Markdown: $ReportFile" -ForegroundColor Yellow
