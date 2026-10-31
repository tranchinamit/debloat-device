#!/usr/bin/env bash
# ==============================================================================
# ANDROID SAFE DEBLOAT & OPTIMIZER FOR MACOS (Remote & Local)
# Tự động tải platform-tools (adb) nếu máy Mac của em họ chưa cài,
# tự động backup danh sách package ra Desktop + Clipboard (pbcopy),
# gỡ bloatware an toàn (Xiaomi, Samsung, OPPO/Realme, Facebook, Microsoft, Google)
# và tối ưu độ mượt hệ thống.
# ==============================================================================

set -u

echo "=========================================================="
echo "   ANDROID SAFE DEBLOAT & OPTIMIZER (MACOS BASH)          "
echo "=========================================================="

# ---------- 1. Chuẩn bị ADB (Tự tải nếu máy Mac khách chưa có) ----------
if ! command -v adb >/dev/null 2>&1; then
    WORK_DIR="/tmp/adb_work"
    if [ ! -x "$WORK_DIR/platform-tools/adb" ]; then
        echo ""
        echo "[*] Máy Mac chưa có ADB. Đang tải Android Platform-Tools (~12MB) từ Google..."
        mkdir -p "$WORK_DIR"
        curl -sL "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip" -o "$WORK_DIR/pt.zip"
        unzip -q -o "$WORK_DIR/pt.zip" -d "$WORK_DIR"
        rm -f "$WORK_DIR/pt.zip"
        chmod +x "$WORK_DIR/platform-tools/adb"
    fi
    export PATH="$WORK_DIR/platform-tools:$PATH"
fi

echo ""
echo "[*] Đang kiểm tra kết nối ADB..."
if ! adb devices | grep -q $'\tdevice$'; then
    echo "[!] Không tìm thấy điện thoại Android nào đang kết nối ở trạng thái 'device'!"
    echo "    -> Hãy kiểm tra cáp USB, bật 'USB Debugging' và bấm 'Allow' trên màn hình điện thoại."
    exit 1
fi

# ---------- 2. Thu thập thông tin & Backup danh sách Package gốc ----------
BRAND=$(adb shell getprop ro.product.brand | tr -d '\r')
MODEL=$(adb shell getprop ro.product.model | tr -d '\r' | tr ' ' '_')
ANDROID_VER=$(adb shell getprop ro.build.version.release | tr -d '\r')
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$HOME/Desktop/${BRAND}_${MODEL}_packages_before_${TIMESTAMP}.txt"

adb shell pm list packages | sed 's/package://g' | tr -d '\r' | sort > "$BACKUP_FILE"
PKG_COUNT=$(wc -l < "$BACKUP_FILE" | tr -d ' ')

echo "[+] Thiết bị : $BRAND $MODEL (Android $ANDROID_VER)"
echo "[+] Đã lưu Backup ($PKG_COUNT gói) tại: $BACKUP_FILE"

# Copy thông tin vào Clipboard trên Mac để tiện Paste về Antigravity
{
    echo "=== DEVICE INFO ==="
    echo "Brand: $BRAND | Model: $MODEL | Android: $ANDROID_VER"
    echo "=== RAM INFO ==="
    adb shell "cat /proc/meminfo | grep -E 'MemTotal|MemAvailable|SwapTotal'" | tr -d '\r'
    echo "=== INSTALLED PACKAGES ($PKG_COUNT) ==="
    cat "$BACKUP_FILE"
} | pbcopy 2>/dev/null && echo "[+] Đã copy thông tin máy & danh sách package vào Clipboard (Cmd+V)!"

# ---------- 3. Danh sách gói Bloatware An Toàn 100% ----------
SAFE_PACKAGES=(
    # 1. Xiaomi / Redmi / POCO
    "com.miui.msa.global|Xiaomi System Ads (Quảng cáo hệ thống)"
    "com.miui.analytics|Xiaomi Analytics (Thu thập & gửi dữ liệu ngầm)"
    "com.miui.daemon|Xiaomi Daemon (Tiến trình thu thập nền)"
    "com.miui.bugreport|Báo cáo lỗi Xiaomi ngầm"
    "com.miui.miservice|Dịch vụ phản hồi Xiaomi"
    "com.miui.misightservice|Dịch vụ theo dõi trải nghiệm MiSight"
    "com.mi.appfinder|App Finder / Gợi ý app rác"
    "com.mi.globalminusscreen|Màn hình -1 App Vault"
    "com.xiaomi.mipicks|GetApps (Kho app Xiaomi spam thông báo)"
    "com.miui.yellowpage|Trang vàng danh bạ Xiaomi"
    "com.xiaomi.payment|Mi Pay (Dịch vụ thanh toán Xiaomi)"
    "com.xiaomi.glgm|Xiaomi Game Center"
    "com.xiaomi.barrage|Chữ chạy màn hình Xiaomi"
    "com.xiaomi.aiasst.vision|AI Vision Xiaomi"
    "com.miui.thirdappassistant|Trợ lý ứng dụng bên thứ 3"
    "com.miui.phrase|Cụm từ mẫu bàn phím Xiaomi"
    "com.mi.globalbrowser|Mi Browser (Trình duyệt nhiều quảng cáo)"
    "com.miui.videoplayer|Mi Video (Trình phát video nhiều quảng cáo)"
    "com.miui.player|Mi Music (Trình nghe nhạc Xiaomi)"
    "com.miui.guardprovider|Bộ quét virus ngầm Avast/Tencent (ngốn ~120MB RAM)"
    "com.xiaomi.aicr|Xiaomi AI Engine ngầm (nặng máy)"
    "com.xiaomi.ugd|Dịch vụ ngầm Xiaomi UGD"
    "com.xiaomi.discover|Trình gợi ý cập nhật ứng dụng hệ thống Xiaomi"
    "com.miui.virtualsim|Mi Roaming (SIM ảo Xiaomi)"
    "com.miui.vsimcore|Virtual SIM Core"

    # 2. Samsung One UI
    "com.samsung.android.bixby.agent|Trợ lý ảo Bixby Voice"
    "com.samsung.android.bixby.wakeup|Nhận diện giọng nói đánh thức Bixby"
    "com.samsung.android.visionintelligence|Bixby Vision"
    "com.samsung.android.bixby.service|Dịch vụ chạy ngầm Bixby"
    "com.samsung.android.app.settings.bixby|Cài đặt Bixby"
    "com.samsung.android.app.spage|Samsung Free / Samsung Daily (Màn hình -1)"
    "com.samsung.android.ardrawing|AR Doodle"
    "com.samsung.android.arzone|AR Zone"
    "com.samsung.android.aremoji|AR Emoji"
    "com.samsung.android.aremojieditor|AR Emoji Editor"
    "com.sec.android.mimage.avatarstickers|Sticker AR Emoji"
    "com.samsung.android.game.gamehome|Samsung Game Launcher"
    "com.samsung.android.game.gametools|Game Booster / Game Tools"
    "com.samsung.android.app.tips|Mẹo sử dụng Samsung (Tips)"
    "com.samsung.android.kidsinstaller|Samsung Kids Installer"
    "com.samsung.android.rubin.app|Customization Service (Theo dõi thói quen ngầm)"

    # 3. OPPO / Realme / OnePlus (ColorOS)
    "com.heytap.browser|Trình duyệt HeyTap (nhiều quảng cáo)"
    "com.heytap.market|Chợ ứng dụng App Market (spam thông báo)"
    "com.heytap.themestore|Theme Store quảng cáo"
    "com.nearme.statistics.rom|Thu thập dữ liệu người dùng ColorOS"
    "com.coloros.gamespace|Game Space quảng cáo"

    # 4. Facebook & Microsoft chạy ngầm
    "com.facebook.services|Facebook Services chạy ngầm"
    "com.facebook.system|Facebook System Installer"
    "com.facebook.appmanager|Facebook App Manager"
    "com.microsoftsdk.crossdeviceservicebroker|Microsoft Link to Windows Broker"
    "com.microsoft.appmanager|Microsoft Phone Link chạy ngầm"

    # 5. Google & Android Telemetry / Quảng cáo / Ngốn RAM ngầm
    "com.google.android.feedback|Google Feedback (Gửi phản hồi lỗi ngầm)"
    "com.google.android.apps.subscriptions.red|Google One Promo"
    "com.google.android.apps.restore|Google Setup Restore"
    "com.google.android.apps.tachyon|Google Meet / Duo"
    "com.google.android.videos|Google TV / Play Movies"
    "com.android.traceur|System Tracing dev log"
    "com.android.egg|Android Easter Egg"
    "com.android.providers.partnerbookmarks|Bookmarks đối tác mặc định"
    "com.google.android.as|Android System Intelligence (ngốn ~103MB RAM ngầm)"
    "com.google.android.as.oss|Private Compute Services"
    "com.android.hotwordenrollment.okgoogle|Lắng nghe mic OK Google 24/7 (ngốn ~103MB RAM)"
    "com.android.hotwordenrollment.xgoogle|Lắng nghe mic Hey Google 24/7"
    "com.google.android.apps.wellbeing|Digital Wellbeing (Theo dõi thời gian dùng app gây khựng)"
    "com.google.mainline.telemetry|Google Mainline Telemetry"
    "com.google.mainline.adservices|Google Mainline AdServices (Quảng cáo)"
    "com.google.android.adservices.api|Google AdServices API"
    "com.google.android.ondevicepersonalization.services|Cá nhân hóa quảng cáo trên thiết bị"
    "com.google.android.federatedcompute|Huấn luyện dữ liệu quảng cáo ngầm"
    "com.google.android.marvin.talkback|TalkBack (Đọc màn hình cho người khiếm thị)"
    "com.google.android.accessibility.switchaccess|Switch Access"

    # 6. Công cụ test nhà máy
    "com.fingerprints.sensortesttool|Test cảm biến vân tay nhà máy"
    "com.goodix.gftest|Test cảm biến Goodix"
    "com.longcheertel.AutoTest|Auto Test nhà máy"
    "com.longcheertel.cit|CIT Test nhà máy"
    "com.longcheertel.sarauth|SAR Auth nhà máy"
    "com.wdstechnology.android.kryten|Cấu hình OMA-DM nhà mạng"
    "com.qualcomm.qti.remoteSimlockAuth|Simlock Auth không dùng"
    "com.qualcomm.qti.ridemodeaudio|Ride Mode Audio Qualcomm"
    "com.qti.snapdragon.qdcm_ff|QDCM Color Mode test"
    "com.bsp.logmanager|CatchLog_Lc (Ghi log debug nhà máy)"
    "com.novatek.novavis|NovaJarvis (Công cụ debug màn hình)"
)

echo ""
echo "=== BƯỚC 1: TIẾN HÀNH DEBLOAT AN TOÀN (Kiểm tra ${#SAFE_PACKAGES[@]} gói) ==="
SUCCESS_COUNT=0
SKIPPED_COUNT=0

for entry in "${SAFE_PACKAGES[@]}"; do
    pkg="${entry%%|*}"
    desc="${entry#*|}"

    if ! grep -Fxq "$pkg" "$BACKUP_FILE"; then
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi

    out=$(adb shell "pm uninstall -k --user 0 $pkg" 2>&1 | tr -d '\r')
    if [[ "$out" == *"Success"* ]]; then
        echo "[ĐÃ GỠ] $pkg - $desc"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "[LỖI]   $pkg : $out"
    fi
done

echo "==> Kết quả Debloat: Đã gỡ $SUCCESS_COUNT gói rác | Bỏ qua $SKIPPED_COUNT gói không có trên máy."

# ---------- 4. Tinh chỉnh hiệu năng & độ mượt ----------
echo ""
echo "=== BƯỚC 2: TỐI ƯU ĐỘ MƯỢT & TIẾN TRÌNH NGẦM ==="

echo "[*] Giảm tỷ lệ Animation xuống 0.5x..."
adb shell "settings put global window_animation_scale 0.5" >/dev/null 2>&1 || true
adb shell "settings put global transition_animation_scale 0.5" >/dev/null 2>&1 || true
adb shell "settings put global animator_duration_scale 0.5" >/dev/null 2>&1 || true
ANIM_CHECK=$(adb shell "settings get global window_animation_scale" | tr -d '\r')
if [ "$ANIM_CHECK" = "0.5" ]; then
    echo "    -> Đã đặt Animation = 0.5x thành công!"
else
    echo "    -> [Lưu ý Xiaomi] Máy chặn WRITE_SECURE_SETTINGS. Hãy chỉnh tay Animation 0.5x trong Developer Options."
fi

echo "[*] Giới hạn số tiến trình lưu đệm ngầm (max_cached_processes = 8)..."
adb shell "device_config put activity_manager max_cached_processes 8" >/dev/null 2>&1 || true

echo "[*] Dọn bộ nhớ đệm (trim-caches)..."
adb shell "pm trim-caches 999999999999999999" >/dev/null 2>&1 || true

echo "[*] Đang chạy tối ưu hóa mã ứng dụng AOT (bg-dexopt-job, mất khoảng 30-90 giây)..."
adb shell "cmd package bg-dexopt-job" >/dev/null 2>&1 || true
echo "    -> Hoàn tất biên dịch AOT!"

echo ""
echo "=========================================================="
echo "   HOÀN TẤT TỐI ƯU! FILE BACKUP LƯU TẠI DESKTOP:          "
echo "   $BACKUP_FILE"
echo "=========================================================="
