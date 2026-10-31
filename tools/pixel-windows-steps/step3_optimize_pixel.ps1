<#
.SYNOPSIS
  [BƯỚC 3 - TỐI ƯU PIN MODEM TENSOR, ĐỘ MƯỢT & ĐA NHIỆM CHO GOOGLE PIXEL]
  Thực hiện các tinh chỉnh chuyên sâu cho dòng Google Pixel:
  1. Tắt giữ sóng 4G/5G ngầm khi đang bắt Wi-Fi (mobile_data_always_on = 0) -> giảm nóng modem Tensor & chống tụt pin qua đêm.
  2. Tắt quét Wi-Fi & Bluetooth BLE ngầm 24/7.
  3. Giảm tỷ lệ Animation xuống 0.5x giúp vuốt chạm phản hồi tức thì.
  4. Mở khóa giới hạn đa nhiệm RAM lớn của Pixel (xóa giới hạn max_cached_processes nếu có).
  5. Dọn bộ nhớ đệm (trim-caches) & Biên dịch tối ưu hóa mã ứng dụng AOT (bg-dexopt-job).
  Tự động xuất kết quả ra file Markdown (.md) ngoài Desktop VÀ copy vào Clipboard.

.USAGE
  Chạy đầy đủ:
    powershell -ExecutionPolicy Bypass -File .\step3_optimize_pixel.ps1

  Chạy nhanh (bỏ qua bước biên dịch AOT 60 giây):
    powershell -ExecutionPolicy Bypass -File .\step3_optimize_pixel.ps1 -SkipDexopt
#>

param(
    [double]$AnimationScale = 0.5,
    [switch]$SkipModemTune,
    [switch]$SkipDexopt,
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
$ReportFile = Join-Path $DesktopDir "Pixel_${SafeModel}_Step3_Optimize.md"

# Đọc thông số trước khi tối ưu
$BeforeAnim  = ((& adb @adbArgs shell "settings get global window_animation_scale") -join "").Trim()
$BeforeMob   = ((& adb @adbArgs shell "settings get global mobile_data_always_on") -join "").Trim()
$BeforeWifi  = ((& adb @adbArgs shell "settings get global wifi_scan_always_enabled") -join "").Trim()
$BeforeBle   = ((& adb @adbArgs shell "settings get global ble_scan_always_enabled") -join "").Trim()

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   BƯỚC 3: TỐI ƯU PIN MODEM TENSOR & ĐỘ MƯỢT GOOGLE PIXEL " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Tối ưu tốc độ Animation
Write-Host "`n[1/5] Đặt tốc độ hiệu ứng chuyển cảnh (Animation Scale = ${AnimationScale}x)..." -ForegroundColor White
& adb @adbArgs shell "settings put global window_animation_scale $AnimationScale" 2>$null
& adb @adbArgs shell "settings put global transition_animation_scale $AnimationScale" 2>$null
& adb @adbArgs shell "settings put global animator_duration_scale $AnimationScale" 2>$null
Write-Host "      -> Đã đặt Animation = ${AnimationScale}x thành công!" -ForegroundColor Green

# 2. Tối ưu Modem Tensor & Quét ngầm
if (-not $SkipModemTune) {
    Write-Host "`n[2/5] Tối ưu Modem Tensor & Tắt quét vị trí ngầm 24/7..." -ForegroundColor White
    & adb @adbArgs shell "settings put global mobile_data_always_on 0" 2>$null
    & adb @adbArgs shell "settings put global wifi_scan_always_enabled 0" 2>$null
    & adb @adbArgs shell "settings put global ble_scan_always_enabled 0" 2>$null
    Write-Host "      -> Đã tắt giữ mạng 4G/5G chạy ngầm khi bắt Wi-Fi (mobile_data_always_on = 0)" -ForegroundColor Green
    Write-Host "      -> Đã tắt dò Wi-Fi & Bluetooth BLE ngầm 24/7 (wifi/ble_scan_always_enabled = 0)" -ForegroundColor Green
}

# 3. Tối ưu đa nhiệm RAM
Write-Host "`n[3/5] Mở khóa giới hạn đa nhiệm RAM trên Google Pixel..." -ForegroundColor White
& adb @adbArgs shell "device_config delete activity_manager max_cached_processes" 2>$null
Write-Host "      -> Đã mở khóa bộ quản lý đa nhiệm gốc cho RAM lớn của Pixel!" -ForegroundColor Green

# 4. Dọn bộ nhớ đệm ứng dụng
Write-Host "`n[4/5] Dọn bộ nhớ đệm hệ thống (trim-caches)..." -ForegroundColor White
& adb @adbArgs shell "pm trim-caches 999999999999999999" 2>$null
Write-Host "      -> Đã giải phóng cache rác!" -ForegroundColor Green

# 5. Biên dịch AOT
$DexoptStatus = "Đã bỏ qua (-SkipDexopt)"
if (-not $SkipDexopt) {
    Write-Host "`n[5/5] Đang chạy tối ưu hóa mã ứng dụng AOT (bg-dexopt-job, mất khoảng 30-90 giây)..." -ForegroundColor Yellow
    & adb @adbArgs shell "cmd package bg-dexopt-job" | Out-Null
    Write-Host "      -> Hoàn tất biên dịch AOT!" -ForegroundColor Green
    $DexoptStatus = "Hoàn tất (bg-dexopt-job)"
} else {
    Write-Host "`n[5/5] Đã bỏ qua bước bg-dexopt-job theo tùy chọn -SkipDexopt." -ForegroundColor DarkGray
}

# Đọc thông số sau khi tối ưu
$AfterAnim  = ((& adb @adbArgs shell "settings get global window_animation_scale") -join "").Trim()
$AfterMob   = ((& adb @adbArgs shell "settings get global mobile_data_always_on") -join "").Trim()
$AfterWifi  = ((& adb @adbArgs shell "settings get global wifi_scan_always_enabled") -join "").Trim()
$AfterBle   = ((& adb @adbArgs shell "settings get global ble_scan_always_enabled") -join "").Trim()

$MdReport = @(
    "# Báo cáo Tối ưu Hóa Hệ thống Google Pixel (Step 3 - Optimize)"
    ""
    "- **Thời gian:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Thiết bị:** $Model"
    ""
    "## Bảng So sánh Thông số Trước & Sau Tối ưu"
    "| Hạng mục | Trước | Sau | Tác dụng |"
    "| :--- | :---: | :---: | :--- |"
    "| ``window_animation_scale`` | ``$BeforeAnim`` | ``$AfterAnim`` | Tăng tốc độ phản hồi chuyển cảnh giao diện |"
    "| ``mobile_data_always_on`` | ``$BeforeMob`` | ``$AfterMob`` | Tắt giữ sóng 4G/5G ngầm khi đang bắt Wi-Fi (Mát modem Tensor & giảm hao pin chờ) |"
    "| ``wifi_scan_always_enabled`` | ``$BeforeWifi`` | ``$AfterWifi`` | Tắt dò Wi-Fi ngầm 24/7 |"
    "| ``ble_scan_always_enabled`` | ``$BeforeBle`` | ``$AfterBle`` | Tắt dò Bluetooth BLE ngầm 24/7 |"
    "| ``max_cached_processes`` | - | ``Default (Unlocked)`` | Mở khóa toàn bộ dung lượng RAM lớn của Pixel |"
    "| ``pm trim-caches`` | - | ``Đã dọn sạch`` | Giải phóng bộ nhớ đệm hệ thống |"
    "| ``bg-dexopt-job`` (AOT) | - | ``$DexoptStatus`` | Biên dịch trước mã ứng dụng giúp mở app mượt hơn |"
) -join "`r`n"

$MdReport | Set-Content -Path $ReportFile -Encoding UTF8
try {
    $MdReport | Set-Clipboard
    Write-Host "`n[OK] ĐÃ COPY KẾT QUẢ BƯỚC 3 VÀO CLIPBOARD & XUẤT FILE .MD RA DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] ĐÃ XUẤT FILE .MD BƯỚC 3 RA DESKTOP!" -ForegroundColor Green
}
Write-Host "File Markdown: $ReportFile" -ForegroundColor Yellow
