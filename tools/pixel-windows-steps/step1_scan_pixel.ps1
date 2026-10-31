<#
.SYNOPSIS
  [BƯỚC 1 - CHỈ QUÉT & PHÂN TÍCH] (100% Read-Only - Không xóa hay thay đổi bất kỳ thứ gì)
  Tự động tải ADB nếu máy tính chưa có, kiểm tra kết nối Google Pixel,
  thu thập thông tin Phần cứng, Độ chai Pin (Cycle Count), RAM, Bộ nhớ, Modem,
  Danh sách App người dùng & Bloatware hệ thống.
  Tự động xuất file Markdown (.md) ra Desktop VÀ copy vào Clipboard.

.USAGE
  powershell -ExecutionPolicy Bypass -File .\step1_scan_pixel.ps1
#>

param(
    [string]$Device = ""
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   BƯỚC 1: QUÉT & PHÂN TÍCH CHUYÊN SÂU GOOGLE PIXEL       " -ForegroundColor Cyan
Write-Host "   (Chế độ An Toàn: Chỉ đọc thông số, không sửa đổi máy)  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# ---------- 1. Chuẩn bị ADB ----------
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    $WorkDir = "C:\adb_work"
    $AdbExe = "$WorkDir\platform-tools\adb.exe"
    if (-not (Test-Path $AdbExe)) {
        Write-Host "`n[*] Máy chưa có ADB. Đang tải Android Platform-Tools (~12MB) từ Google..." -ForegroundColor Yellow
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

Write-Host "`n[*] Đang kiểm tra kết nối ADB với Google Pixel..." -ForegroundColor Cyan
$devices = (& adb @adbArgs devices) | Select-Object -Skip 1 | Where-Object { $_ -match "\t(device|unauthorized)$" }
if (-not $devices) {
    Write-Host "[!] Chưa tìm thấy điện thoại trên cổng USB!" -ForegroundColor Red
    Write-Host "    1. Trên Pixel: Vào Settings -> About phone -> Bấm 7 lần vào 'Build number'." -ForegroundColor Yellow
    Write-Host "    2. Vào Settings -> System -> Developer options -> Bật 'USB debugging'." -ForegroundColor Yellow
    Write-Host "    3. Cắm cáp USB và bấm 'Allow' (Cho phép) trên màn hình Pixel." -ForegroundColor Yellow
    exit 1
}
if ($devices -match "unauthorized") {
    Write-Host "[!] Điện thoại đang hiện bảng hỏi quyền trên màn hình!" -ForegroundColor Yellow
    Write-Host "    -> Hãy nhìn màn hình Pixel, tích 'Always allow from this computer' và bấm 'Allow'." -ForegroundColor Yellow
    exit 1
}

# ---------- 2. Thu thập thông tin chi tiết ----------
Write-Host "[*] Đang đọc thông số Phần cứng, Pin, RAM, Bộ nhớ và Ứng dụng..." -ForegroundColor Green

$Brand       = ((& adb @adbArgs shell getprop ro.product.brand) -join "").Trim()
$Model       = ((& adb @adbArgs shell getprop ro.product.model) -join "").Trim()
$DeviceCode  = ((& adb @adbArgs shell getprop ro.product.device) -join "").Trim()
$SoC         = ((& adb @adbArgs shell getprop ro.hardware.chipname) -join "").Trim()
if (-not $SoC) { $SoC = ((& adb @adbArgs shell getprop ro.board.platform) -join "").Trim() }
$AndroidVer  = ((& adb @adbArgs shell getprop ro.build.version.release) -join "").Trim()
$BuildId     = ((& adb @adbArgs shell getprop ro.build.id) -join "").Trim()
$SecPatch    = ((& adb @adbArgs shell getprop ro.build.version.security_patch) -join "").Trim()
$Baseband    = ((& adb @adbArgs shell getprop gsm.version.baseband) -join "").Trim()

# Đường dẫn lưu file trên Desktop
$Timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$DesktopDir = [Environment]::GetFolderPath("Desktop")
$SafeModel  = $Model -replace '\s+', '_'
$BackupFile = Join-Path $DesktopDir "Pixel_${SafeModel}_packages_backup_${Timestamp}.txt"
$ReportFile = Join-Path $DesktopDir "Pixel_${SafeModel}_Step1_Scan.md"

$AllEnabledPkgs = (& adb @adbArgs shell pm list packages -e) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object
$AllUserPkgs    = (& adb @adbArgs shell pm list packages -3) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object
$AllSystemPkgs  = (& adb @adbArgs shell pm list packages -s -e) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object
$AllDisabled    = (& adb @adbArgs shell pm list packages -d) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object

$AllEnabledPkgs | Set-Content -Path $BackupFile -Encoding UTF8

# Pin & Nhiệt độ
$BatteryDump = (& adb @adbArgs shell "dumpsys battery") -join "`n"
$BattCycle   = ((& adb @adbArgs shell "cat /sys/class/power_supply/battery/cycle_count 2>/dev/null") -join "").Trim()
$BattFull    = ((& adb @adbArgs shell "cat /sys/class/power_supply/battery/charge_full 2>/dev/null") -join "").Trim()
$BattDesign  = ((& adb @adbArgs shell "cat /sys/class/power_supply/battery/charge_full_design 2>/dev/null") -join "").Trim()

# Bộ nhớ & RAM
$StorageDf   = (& adb @adbArgs shell "df -h /data") -join "`n"
$MemInfo     = (& adb @adbArgs shell "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree'") -join "`n"
$TopMem      = (& adb @adbArgs shell "dumpsys meminfo | sed -n '/Total PSS by process:/,/Total PSS by OOM adjustment:/p' | head -n 25") -join "`n"

# Cài đặt hệ thống hiện tại
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

# Tạo nội dung báo cáo Markdown (.md)
$ReportLines = @(
    "# Báo cáo Quét Chuyên sâu Google Pixel (Step 1 - Scan)"
    ""
    "- **Thời gian quét:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Thiết bị:** $Brand $Model (Codename: ``$DeviceCode``)"
    "- **Vi xử lý (SoC):** ``$SoC``"
    "- **Hệ điều hành:** Android $AndroidVer (Build: ``$BuildId`` | Vá bảo mật: ``$SecPatch``)"
    "- **Baseband Modem:** ``$Baseband``"
    ""
    "## 1. Tình trạng Pin & Nhiệt độ (Battery Health)"
    "- **Kernel Cycle Count:** ``$BattCycle``"
    "- **Kernel Charge Full (uAh):** ``$BattFull``"
    "- **Kernel Charge Design (uAh):** ``$BattDesign``"
    "``````text"
    $BatteryDump
    "``````"
    ""
    "## 2. Bộ nhớ Lưu trữ (/data)"
    "``````text"
    $StorageDf
    "``````"
    ""
    "## 3. Thông số RAM & Swap"
    "``````text"
    $MemInfo
    "``````"
    ""
    "## 4. Cài đặt Hệ thống Hiện tại"
    "| Thông số | Giá trị hiện tại |"
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
    "## 5. Top Tiến trình Ngốn RAM Nhiều nhất"
    "``````text"
    $TopMem
    "``````"
    ""
    "## 6. Ứng dụng Người dùng Đã cài ($($AllUserPkgs.Count) apps)"
    "``````text"
    ($AllUserPkgs -join "`n")
    "``````"
    ""
    "## 7. Gói Hệ thống Đang bật ($($AllSystemPkgs.Count) packages)"
    "``````text"
    ($AllSystemPkgs -join "`n")
    "``````"
    ""
    "## 8. Gói Đã bị Vô hiệu hóa / Gỡ trước đó ($($AllDisabled.Count) packages)"
    "``````text"
    ($AllDisabled -join "`n")
    "``````"
)

$ReportText = $ReportLines -join "`r`n"
$ReportText | Set-Content -Path $ReportFile -Encoding UTF8

try {
    $ReportText | Set-Clipboard
    Write-Host "`n[OK] ĐÃ COPY BÁO CÁO VÀO CLIPBOARD & XUẤT FILE .MD RA DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] ĐÃ XUẤT FILE BÁO CÁO .MD RA DESKTOP!" -ForegroundColor Green
}

Write-Host "`n--- TÓM TẮT KẾT QUẢ BƯỚC 1 ---" -ForegroundColor Cyan
Write-Host "Thiết bị         : $Brand $Model ($DeviceCode) - Chip $SoC - Android $AndroidVer"
Write-Host "Tổng gói đang bật: $($AllEnabledPkgs.Count) (App người dùng: $($AllUserPkgs.Count) | Hệ thống: $($AllSystemPkgs.Count))"
Write-Host "File Markdown    : $ReportFile" -ForegroundColor Yellow
Write-Host "File Backup gốc  : $BackupFile"
Write-Host "-> Bạn có thể bấm Ctrl+V (dán trực tiếp) hoặc gửi file .md ngoài Desktop để phân tích!" -ForegroundColor Green
