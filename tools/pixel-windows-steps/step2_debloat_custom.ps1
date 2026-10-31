<#
.SYNOPSIS
  [BƯỚC 2 - GỠ BLOATWARE THEO LỰA CHỌN]
  Chạy sau khi đã xem kết quả phân tích từ Bước 1 (step1_scan_pixel.ps1).
  Hỗ trợ chế độ xem trước (-DryRun), chọn nhóm (-Group), hoặc truyền thêm gói tùy ý (-ExtraPackages).
  Khóa bảo vệ cứng các gói tính năng độc quyền của Google Pixel (Now Playing, eSIM, AICore, Camera, Launcher).
  Tự động xuất kết quả ra file Markdown (.md) ngoài Desktop VÀ copy vào Clipboard.

.USAGE
  1. Xem trước những gói sẽ được gỡ trên máy (chưa gỡ thật):
     powershell -ExecutionPolicy Bypass -File .\step2_debloat_custom.ps1 -DryRun

  2. Gỡ toàn bộ các nhóm rác an toàn (Nhà mạng Mỹ + Telemetry Quảng cáo + App rác cài sẵn):
     powershell -ExecutionPolicy Bypass -File .\step2_debloat_custom.ps1

  3. Gỡ kèm thêm các gói cụ thể do bạn chỉ định sau Bước 1:
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
$ReportFile = Join-Path $DesktopDir "Pixel_${SafeModel}_Step2_Debloat.md"

# Danh sách gói BẢO VỆ TUYỆT ĐỐI trên Google Pixel (Không bao giờ cho phép gỡ nhầm)
$ProtectedPixelPackages = [System.Collections.Generic.HashSet[string]]::new([string[]]@(
    "com.google.android.as",                     # Android System Intelligence (Now Playing, Live Caption, Copy chữ đa nhiệm)
    "com.google.android.as.oss",                 # Private Compute Services
    "com.google.android.aicore",                 # Google AICore (Pixel AI)
    "com.google.android.euicc",                  # Quản lý eSIM trên Pixel
    "com.google.android.ims",                    # Carrier Services (VoLTE / Wi-Fi Calling)
    "com.google.android.apps.nexuslauncher",     # Pixel Launcher gốc
    "com.google.android.GoogleCamera",           # Pixel Camera gốc
    "com.google.android.gms",                    # Google Play Services
    "com.android.vending",                       # Google Play Store
    "com.google.android.dialer",                 # Điện thoại gốc
    "com.google.android.apps.messaging",         # Tin nhắn gốc của Pixel
    "com.google.android.contacts",               # Danh bạ gốc
    "com.google.android.apps.photos"             # Google Photos (Thư viện ảnh gốc của Pixel)
))

# Nhóm 1: Rác nhà mạng Mỹ/Nhật ẩn sẵn trong ROM Google Pixel
$CarrierPackages = @(
    @{ Pkg = "com.verizon.mips.services";       Desc = "My Verizon Services (Rác nhà mạng Verizon ngầm)" },
    @{ Pkg = "com.verizon.llkagent";            Desc = "Verizon LLK Agent (Rác nhà mạng Verizon)" },
    @{ Pkg = "com.vzw.apnlib";                  Desc = "Verizon APN Library" },
    @{ Pkg = "com.customermobile.preload.vzw";  Desc = "Verizon Preload Agent" },
    @{ Pkg = "com.att.iqi";                     Desc = "AT&T Carrier IQ Telemetry (Theo dõi ngầm nhà mạng AT&T)" },
    @{ Pkg = "com.tmobile.pr.adapt";            Desc = "T-Mobile Adapt (Dịch vụ nhà mạng T-Mobile ngầm)" },
    @{ Pkg = "com.sprint.ms.smf.services";      Desc = "Sprint Services (Dịch vụ nhà mạng Sprint ngầm)" },
    @{ Pkg = "com.sprint.ce.updater";           Desc = "Sprint Carrier Updater" },
    @{ Pkg = "com.google.omadm.trigger";        Desc = "OMA-DM Carrier Trigger (Cấu hình nhà mạng Mỹ)" },
    @{ Pkg = "com.android.omadm.service";       Desc = "OMA-DM Carrier Service" },
    @{ Pkg = "com.nttdocomo.android.docomoset"; Desc = "Docomo Carrier Settings (Nhà mạng Nhật)" },
    @{ Pkg = "jp.softbank.mb.ichinaviclt";      Desc = "SoftBank Navigation (Nhà mạng Nhật)" }
)

# Nhóm 2: Dịch vụ Quảng cáo, Chẩn đoán & Telemetry chạy ngầm của Google
$TelemetryPackages = @(
    @{ Pkg = "com.google.mainline.telemetry";                       Desc = "Google Mainline Telemetry (Thu thập dữ liệu ngầm)" },
    @{ Pkg = "com.google.mainline.adservices";                      Desc = "Google Mainline AdServices (Dịch vụ quảng cáo)" },
    @{ Pkg = "com.google.android.adservices.api";                   Desc = "Google AdServices API (Theo dõi quảng cáo)" },
    @{ Pkg = "com.google.android.ondevicepersonalization.services"; Desc = "Cá nhân hóa quảng cáo trên thiết bị" },
    @{ Pkg = "com.google.android.federatedcompute";                 Desc = "Huấn luyện dữ liệu quảng cáo ngầm" },
    @{ Pkg = "com.google.android.feedback";                         Desc = "Google Feedback (Gửi báo cáo lỗi ngầm)" },
    @{ Pkg = "com.android.traceur";                                 Desc = "System Tracing (Ghi log nhà phát triển)" },
    @{ Pkg = "com.google.android.apps.helprtc";                     Desc = "Pixel Support Video Share chạy ngầm" },
    @{ Pkg = "com.google.android.apps.diagnosticstool";             Desc = "Pixel Diagnostics Tool" }
)

# Nhóm 3: App cài sẵn ít dùng / Tốn RAM nền
$BloatAppsPackages = @(
    @{ Pkg = "com.google.android.apps.tips";                  Desc = "Pixel Tips (Mẹo sử dụng Pixel chạy ngầm)" },
    @{ Pkg = "com.android.retaildemo";                        Desc = "Retail Demo Mode (Chế độ trưng bày cửa hàng)" },
    @{ Pkg = "com.google.android.retaildemo";                 Desc = "Google Retail Demo" },
    @{ Pkg = "com.google.android.apps.subscriptions.red";     Desc = "Google One Promo" },
    @{ Pkg = "com.google.android.videos";                     Desc = "Google TV / Play Movies" },
    @{ Pkg = "com.google.android.apps.tachyon";               Desc = "Google Meet / Duo" },
    @{ Pkg = "com.google.android.apps.restore";               Desc = "Google Setup Restore (Chỉ dùng lúc mới đập hộp)" },
    @{ Pkg = "com.android.providers.partnerbookmarks";        Desc = "Bookmarks đối tác quảng cáo" },
    @{ Pkg = "com.android.egg";                               Desc = "Android Easter Egg" },
    @{ Pkg = "com.android.hotwordenrollment.okgoogle";        Desc = "Lắng nghe mic OK Google 24/7 (Ngốn RAM & pin chờ)" },
    @{ Pkg = "com.android.hotwordenrollment.xgoogle";         Desc = "Lắng nghe mic Hey Google 24/7" },
    @{ Pkg = "com.google.android.apps.wellbeing";             Desc = "Digital Wellbeing (Theo dõi thời gian dùng máy ngầm)" },
    @{ Pkg = "com.google.android.marvin.talkback";            Desc = "TalkBack (Đọc màn hình cho người khiếm thị)" },
    @{ Pkg = "com.google.android.accessibility.switchaccess"; Desc = "Switch Access" }
)

$TargetList = @()
if ($Group -eq "All" -or $Group -eq "Carrier")   { $TargetList += $CarrierPackages }
if ($Group -eq "All" -or $Group -eq "Telemetry") { $TargetList += $TelemetryPackages }
if ($Group -eq "All" -or $Group -eq "BloatApps") { $TargetList += $BloatAppsPackages }

if ($ExtraPackages) {
    $extras = $ExtraPackages -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($ep in $extras) {
        $TargetList += @{ Pkg = $ep; Desc = "Gói tùy chọn bổ sung theo yêu cầu" }
    }
}

$InstalledRaw = (& adb @adbArgs shell pm list packages -e) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ }
$InstalledSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$InstalledRaw)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   BƯỚC 2: GỠ BLOATWARE GOOGLE PIXEL (Nhóm: $Group)       " -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "   [CHẾ ĐỘ DRY-RUN: CHỈ HIỂN THỊ, CHƯA GỠ THẬT]          " -ForegroundColor Yellow
}
Write-Host "==========================================================" -ForegroundColor Cyan

$RemovedCount = 0
$SkippedCount = 0
$ActionLogs   = @()

foreach ($item in $TargetList) {
    $pkg = $item.Pkg
    $desc = $item.Desc

    if ($ProtectedPixelPackages.Contains($pkg)) {
        Write-Host "[BẢO VỆ PIXEL] $pkg - Đã khóa bảo vệ tính năng gốc của Pixel!" -ForegroundColor Magenta
        $ActionLogs += "| ``$pkg`` | **BẢO VỆ (GIỮ LẠI)** | $desc |"
        continue
    }

    if (-not $InstalledSet.Contains($pkg)) {
        $SkippedCount++
        continue
    }

    if ($DryRun) {
        Write-Host "[SẼ GỠ] $pkg - $desc" -ForegroundColor Yellow
        $ActionLogs += "| ``$pkg`` | **SẼ GỠ (Dry-Run)** | $desc |"
        $RemovedCount++
    } else {
        $out = (& adb @adbArgs shell "pm uninstall -k --user 0 $pkg" 2>&1) -join " "
        if ($out -match "Success") {
            Write-Host "[ĐÃ GỠ] $pkg - $desc" -ForegroundColor Green
            $ActionLogs += "| ``$pkg`` | **ĐÃ GỠ (Success)** | $desc |"
            $RemovedCount++
        } else {
            Write-Host "[LỖI]   $pkg : $out" -ForegroundColor Red
            $ActionLogs += "| ``$pkg`` | **LỖI ($out)** | $desc |"
        }
    }
}

$ModeLabel = if ($DryRun) { "Dry-Run (Xem trước)" } else { "Thực thi Gỡ bỏ" }
$MdReport = @(
    "# Báo cáo Gỡ Bloatware Google Pixel (Step 2 - Debloat)"
    ""
    "- **Thời gian:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "- **Thiết bị:** $Model"
    "- **Chế độ:** $ModeLabel (Nhóm: ``$Group``)"
    "- **Gói bổ sung (ExtraPackages):** $(if ($ExtraPackages) { "``$ExtraPackages``" } else { 'Không có' })"
    "- **Tổng kết:** Đã xử lý **$RemovedCount gói** trên máy | Bỏ qua **$SkippedCount gói** không tồn tại."
    ""
    "## Chi tiết Các gói Đã xử lý"
    "| Package ID | Trạng thái | Mô tả |"
    "| :--- | :--- | :--- |"
    $(if ($ActionLogs.Count -gt 0) { $ActionLogs -join "`r`n" } else { "| *(Không có gói nào trùng khớp trên máy)* | - | - |" })
) -join "`r`n"

$MdReport | Set-Content -Path $ReportFile -Encoding UTF8
try {
    $MdReport | Set-Clipboard
    Write-Host "`n[OK] ĐÃ COPY KẾT QUẢ BƯỚC 2 VÀO CLIPBOARD & XUẤT FILE .MD RA DESKTOP!" -ForegroundColor Green
} catch {
    Write-Host "`n[OK] ĐÃ XUẤT FILE .MD BƯỚC 2 RA DESKTOP!" -ForegroundColor Green
}
Write-Host "File Markdown: $ReportFile" -ForegroundColor Yellow
