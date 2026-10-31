<#
.SYNOPSIS
  All-in-One Android Safe Debloat & Optimization Script for Windows (Remote-friendly).
  Automatically downloads Google Platform-Tools (adb.exe) if missing, backs up installed packages,
  removes safe bloatware (Xiaomi, Samsung, OPPO/Realme, Facebook, Microsoft, Google Telemetry),
  and applies smoothness/RAM optimizations.

.USAGE
  Open PowerShell and run:
  powershell -ExecutionPolicy Bypass -File .\debloat_safe_android.ps1
#>

param(
    [string]$Device = "",
    [switch]$SkipDexopt
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   ANDROID SAFE DEBLOAT & OPTIMIZER (WINDOWS POWERSHELL)  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# ---------- 1. Chuẩn bị ADB (Tự tải nếu máy khách chưa có) ----------
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

Write-Host "`n[*] Đang kiểm tra kết nối ADB..." -ForegroundColor Cyan
$devices = (& adb @adbArgs devices) | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" }
if (-not $devices) {
    Write-Host "[!] Không tìm thấy điện thoại Android nào đang kết nối ở trạng thái 'device'!" -ForegroundColor Red
    Write-Host "    -> Hãy kiểm tra cáp USB, bật 'Gỡ lỗi USB (USB Debugging)' và bấm 'Cho phép (Allow)' trên màn hình điện thoại." -ForegroundColor Yellow
    exit 1
}

# ---------- 2. Thu thập thông tin & Backup danh sách Package gốc ----------
$Brand = ((& adb @adbArgs shell getprop ro.product.brand) -join "").Trim()
$Model = ((& adb @adbArgs shell getprop ro.product.model) -join "").Trim() -replace '\s+', '_'
$AndroidVer = ((& adb @adbArgs shell getprop ro.build.version.release) -join "").Trim()
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$DesktopDir = [Environment]::GetFolderPath("Desktop")
$BackupFile = Join-Path $DesktopDir "${Brand}_${Model}_packages_before_${Timestamp}.txt"

$InstalledRaw = (& adb @adbArgs shell pm list packages) | ForEach-Object { $_.Replace("package:", "").Trim() } | Where-Object { $_ } | Sort-Object
$InstalledSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$InstalledRaw)

$InstalledRaw | Set-Content -Path $BackupFile -Encoding UTF8
Write-Host "[+] Thiết bị : $Brand $Model (Android $AndroidVer)" -ForegroundColor Green
Write-Host "[+] Đã lưu Backup ($($InstalledRaw.Count) gói) tại: $BackupFile" -ForegroundColor Green

# Copy thông tin vào Clipboard để tiện Paste về máy chủ Antigravity
try {
    @(
        "=== DEVICE INFO ==="
        "Brand: $Brand | Model: $Model | Android: $AndroidVer"
        "=== RAM INFO ==="
        (& adb @adbArgs shell "cat /proc/meminfo | grep -E 'MemTotal|MemAvailable|SwapTotal'")
        "=== INSTALLED PACKAGES ($($InstalledRaw.Count)) ==="
        $InstalledRaw
    ) | Set-Clipboard
    Write-Host "[+] Đã copy thông tin máy & danh sách package vào Clipboard!" -ForegroundColor DarkCyan
} catch {}

# ---------- 3. Danh sách gói Bloatware An Toàn 100% ----------
# TUYỆT ĐỐI KHÔNG CHỨA: overlay, GMS Core, Dialer/Contacts/SMS gốc, driver phần cứng Qualcomm/MTK.
$SafeDebloatPackages = @(
    # 1. Quảng cáo, theo dõi, thu thập dữ liệu ngầm của Xiaomi / Redmi / POCO
    @{ Pkg = "com.miui.msa.global"; Desc = "Xiaomi System Ads (Quảng cáo hệ thống)" },
    @{ Pkg = "com.miui.analytics"; Desc = "Xiaomi Analytics (Thu thập & gửi dữ liệu ngầm)" },
    @{ Pkg = "com.miui.daemon"; Desc = "Xiaomi Daemon (Tiến trình thu thập nền)" },
    @{ Pkg = "com.miui.bugreport"; Desc = "Báo cáo lỗi Xiaomi ngầm" },
    @{ Pkg = "com.miui.miservice"; Desc = "Dịch vụ phản hồi Xiaomi" },
    @{ Pkg = "com.miui.misightservice"; Desc = "Dịch vụ theo dõi trải nghiệm MiSight" },
    @{ Pkg = "com.mi.appfinder"; Desc = "App Finder / Gợi ý app rác" },
    @{ Pkg = "com.mi.globalminusscreen"; Desc = "Màn hình -1 App Vault" },
    @{ Pkg = "com.xiaomi.mipicks"; Desc = "GetApps (Kho app Xiaomi spam thông báo)" },
    @{ Pkg = "com.miui.yellowpage"; Desc = "Trang vàng danh bạ Xiaomi" },
    @{ Pkg = "com.xiaomi.payment"; Desc = "Mi Pay (Dịch vụ thanh toán nội địa)" },
    @{ Pkg = "com.xiaomi.glgm"; Desc = "Xiaomi Game Center" },
    @{ Pkg = "com.xiaomi.barrage"; Desc = "Chữ chạy màn hình Xiaomi" },
    @{ Pkg = "com.xiaomi.aiasst.vision"; Desc = "AI Vision Xiaomi" },
    @{ Pkg = "com.miui.thirdappassistant"; Desc = "Trợ lý ứng dụng bên thứ 3" },
    @{ Pkg = "com.miui.phrase"; Desc = "Cụm từ mẫu bàn phím Xiaomi" },
    @{ Pkg = "com.mi.globalbrowser"; Desc = "Mi Browser (Trình duyệt nhiều quảng cáo)" },
    @{ Pkg = "com.miui.videoplayer"; Desc = "Mi Video (Trình phát video nhiều quảng cáo)" },
    @{ Pkg = "com.miui.player"; Desc = "Mi Music (Trình nghe nhạc nhiều quảng cáo)" },
    @{ Pkg = "com.miui.guardprovider"; Desc = "Bộ quét virus ngầm Avast/Tencent (ngốn ~120MB RAM)" },
    @{ Pkg = "com.xiaomi.aicr"; Desc = "Xiaomi AI Engine ngầm (nặng máy)" },
    @{ Pkg = "com.xiaomi.ugd"; Desc = "Dịch vụ ngầm Xiaomi UGD" },
    @{ Pkg = "com.xiaomi.discover"; Desc = "Trình gợi ý cập nhật ứng dụng hệ thống Xiaomi" },
    @{ Pkg = "com.miui.virtualsim"; Desc = "Mi Roaming (SIM ảo Xiaomi)" },
    @{ Pkg = "com.miui.vsimcore"; Desc = "Virtual SIM Core" },

    # 2. Samsung One UI Bloatware (Bixby, AR Zone, Game Launcher, Quảng cáo/Theo dõi)
    @{ Pkg = "com.samsung.android.bixby.agent"; Desc = "Trợ lý ảo Bixby Voice" },
    @{ Pkg = "com.samsung.android.bixby.wakeup"; Desc = "Nhận diện giọng nói đánh thức Bixby" },
    @{ Pkg = "com.samsung.android.visionintelligence"; Desc = "Bixby Vision" },
    @{ Pkg = "com.samsung.android.bixby.service"; Desc = "Dịch vụ chạy ngầm Bixby" },
    @{ Pkg = "com.samsung.android.app.settings.bixby"; Desc = "Cài đặt Bixby" },
    @{ Pkg = "com.samsung.android.app.spage"; Desc = "Samsung Free / Samsung Daily (Màn hình -1)" },
    @{ Pkg = "com.samsung.android.ardrawing"; Desc = "AR Doodle" },
    @{ Pkg = "com.samsung.android.arzone"; Desc = "AR Zone" },
    @{ Pkg = "com.samsung.android.aremoji"; Desc = "AR Emoji" },
    @{ Pkg = "com.samsung.android.aremojieditor"; Desc = "AR Emoji Editor" },
    @{ Pkg = "com.sec.android.mimage.avatarstickers"; Desc = "Sticker AR Emoji" },
    @{ Pkg = "com.samsung.android.game.gamehome"; Desc = "Samsung Game Launcher (Quảng cáo game)" },
    @{ Pkg = "com.samsung.android.game.gametools"; Desc = "Game Booster / Game Tools" },
    @{ Pkg = "com.samsung.android.app.tips"; Desc = "Mẹo sử dụng Samsung (Tips)" },
    @{ Pkg = "com.samsung.android.kidsinstaller"; Desc = "Samsung Kids Installer" },
    @{ Pkg = "com.samsung.android.rubin.app"; Desc = "Customization Service (Theo dõi thói quen ngầm)" },

    # 3. OPPO / Realme / OnePlus (ColorOS) Bloatware
    @{ Pkg = "com.heytap.browser"; Desc = "Trình duyệt HeyTap (nhiều quảng cáo)" },
    @{ Pkg = "com.heytap.market"; Desc = "Chợ ứng dụng App Market (spam thông báo)" },
    @{ Pkg = "com.heytap.themestore"; Desc = "Theme Store quảng cáo" },
    @{ Pkg = "com.nearme.statistics.rom"; Desc = "Thu thập dữ liệu người dùng ColorOS" },
    @{ Pkg = "com.coloros.gamespace"; Desc = "Game Space quảng cáo" },

    # 4. Facebook & Microsoft chạy ngầm
    @{ Pkg = "com.facebook.services"; Desc = "Facebook Services chạy ngầm" },
    @{ Pkg = "com.facebook.system"; Desc = "Facebook System Installer" },
    @{ Pkg = "com.facebook.appmanager"; Desc = "Facebook App Manager" },
    @{ Pkg = "com.microsoftsdk.crossdeviceservicebroker"; Desc = "Microsoft Link to Windows Broker" },
    @{ Pkg = "com.microsoft.appmanager"; Desc = "Microsoft Phone Link chạy ngầm" },

    # 5. Google & Android Telemetry / Quảng cáo / Ngốn RAM ngầm
    @{ Pkg = "com.google.android.feedback"; Desc = "Google Feedback (Gửi phản hồi lỗi ngầm)" },
    @{ Pkg = "com.google.android.apps.subscriptions.red"; Desc = "Google One Promo" },
    @{ Pkg = "com.google.android.apps.restore"; Desc = "Google Setup Restore (Chỉ dùng khi mới đập hộp)" },
    @{ Pkg = "com.google.android.apps.tachyon"; Desc = "Google Meet / Duo" },
    @{ Pkg = "com.google.android.videos"; Desc = "Google TV / Play Movies" },
    @{ Pkg = "com.android.traceur"; Desc = "System Tracing dev log" },
    @{ Pkg = "com.android.egg"; Desc = "Android Easter Egg" },
    @{ Pkg = "com.android.providers.partnerbookmarks"; Desc = "Bookmarks đối tác quảng cáo" },
    @{ Pkg = "com.google.android.as"; Desc = "Android System Intelligence (ngốn ~103MB RAM ngầm)" },
    @{ Pkg = "com.google.android.as.oss"; Desc = "Private Compute Services (đi kèm System Intelligence)" },
    @{ Pkg = "com.android.hotwordenrollment.okgoogle"; Desc = "Lắng nghe mic OK Google 24/7 (ngốn ~103MB RAM)" },
    @{ Pkg = "com.android.hotwordenrollment.xgoogle"; Desc = "Lắng nghe mic Hey Google 24/7" },
    @{ Pkg = "com.google.android.apps.wellbeing"; Desc = "Digital Wellbeing (Theo dõi thời gian dùng app gây khựng)" },
    @{ Pkg = "com.google.mainline.telemetry"; Desc = "Google Mainline Telemetry" },
    @{ Pkg = "com.google.mainline.adservices"; Desc = "Google Mainline AdServices (Quảng cáo)" },
    @{ Pkg = "com.google.android.adservices.api"; Desc = "Google AdServices API" },
    @{ Pkg = "com.google.android.ondevicepersonalization.services"; Desc = "Cá nhân hóa quảng cáo trên thiết bị" },
    @{ Pkg = "com.google.android.federatedcompute"; Desc = "Huấn luyện dữ liệu quảng cáo ngầm" },
    @{ Pkg = "com.google.android.marvin.talkback"; Desc = "TalkBack (Đọc màn hình cho người khiếm thị)" },
    @{ Pkg = "com.google.android.accessibility.switchaccess"; Desc = "Switch Access" },

    # 6. Công cụ kiểm thử / cấu hình rác của nhà máy
    @{ Pkg = "com.fingerprints.sensortesttool"; Desc = "Test cảm biến vân tay nhà máy" },
    @{ Pkg = "com.goodix.gftest"; Desc = "Test cảm biến Goodix" },
    @{ Pkg = "com.longcheertel.AutoTest"; Desc = "Auto Test nhà máy" },
    @{ Pkg = "com.longcheertel.cit"; Desc = "CIT Test nhà máy" },
    @{ Pkg = "com.longcheertel.sarauth"; Desc = "SAR Auth nhà máy" },
    @{ Pkg = "com.wdstechnology.android.kryten"; Desc = "Cấu hình OMA-DM nhà mạng" },
    @{ Pkg = "com.qualcomm.qti.remoteSimlockAuth"; Desc = "Simlock Auth không dùng" },
    @{ Pkg = "com.qualcomm.qti.ridemodeaudio"; Desc = "Ride Mode Audio Qualcomm" },
    @{ Pkg = "com.qti.snapdragon.qdcm_ff"; Desc = "QDCM Color Mode test" },
    @{ Pkg = "com.bsp.logmanager"; Desc = "CatchLog_Lc (Ghi log debug nhà máy)" },
    @{ Pkg = "com.novatek.novavis"; Desc = "NovaJarvis (Công cụ debug màn hình)" }
)

Write-Host "`n=== BƯỚC 1: TIẾN HÀNH DEBLOAT AN TOÀN (Kiểm tra $($SafeDebloatPackages.Count) gói) ===" -ForegroundColor Cyan
$SuccessCount = 0
$SkippedCount = 0

foreach ($item in $SafeDebloatPackages) {
    $pkg = $item.Pkg
    $desc = $item.Desc
    if (-not $InstalledSet.Contains($pkg)) {
        $SkippedCount++
        continue
    }

    $out = (& adb @adbArgs shell "pm uninstall -k --user 0 $pkg" 2>&1) -join " "
    if ($out -match "Success") {
        Write-Host "[ĐÃ GỠ] $pkg - $desc" -ForegroundColor Green
        $SuccessCount++
    } else {
        Write-Host "[LỖI]   $pkg : $out" -ForegroundColor DarkYellow
    }
}
Write-Host "==> Kết quả Debloat: Đã gỡ $SuccessCount gói rác | Bỏ qua $SkippedCount gói không có trên máy." -ForegroundColor Cyan

# ---------- 4. Tinh chỉnh hiệu năng & độ mượt ----------
Write-Host "`n=== BƯỚC 2: TỐI ƯU ĐỘ MƯỢT & TIẾN TRÌNH NGẦM ===" -ForegroundColor Cyan

Write-Host "[*] Giảm tỷ lệ Animation xuống 0.5x..." -ForegroundColor White
& adb @adbArgs shell "settings put global window_animation_scale 0.5" 2>$null
& adb @adbArgs shell "settings put global transition_animation_scale 0.5" 2>$null
& adb @adbArgs shell "settings put global animator_duration_scale 0.5" 2>$null
$animCheck = ((& adb @adbArgs shell "settings get global window_animation_scale") -join "").Trim()
if ($animCheck -eq "0.5") {
    Write-Host "    -> Đã đặt Animation = 0.5x thành công!" -ForegroundColor Green
} else {
    Write-Host "    -> [Lưu ý Xiaomi] Máy chặn quyền WRITE_SECURE_SETTINGS. Hãy chỉnh tay Animation 0.5x trong Developer Options." -ForegroundColor Yellow
}

Write-Host "[*] Giới hạn số tiến trình lưu đệm ngầm (max_cached_processes = 8)..." -ForegroundColor White
& adb @adbArgs shell "device_config put activity_manager max_cached_processes 8" 2>$null

Write-Host "[*] Dọn bộ nhớ đệm (trim-caches)..." -ForegroundColor White
& adb @adbArgs shell "pm trim-caches 999999999999999999" 2>$null

if (-not $SkipDexopt) {
    Write-Host "[*] Đang chạy tối ưu hóa mã ứng dụng AOT (bg-dexopt-job, mất khoảng 30-90 giây)..." -ForegroundColor Yellow
    & adb @adbArgs shell "cmd package bg-dexopt-job" | Out-Null
    Write-Host "    -> Hoàn tất biên dịch AOT!" -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   HOÀN TẤT TỐI ƯU! FILE BACKUP LƯU TẠI DESKTOP:          " -ForegroundColor Green
Write-Host "   $BackupFile" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
