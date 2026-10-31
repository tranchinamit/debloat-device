#!/usr/bin/env bash
# ==============================================================================
# RESTORE ALL ANDROID PACKAGES & SETTINGS ON MACOS
# Khôi phục toàn bộ hoặc 1 gói cụ thể đã gỡ trên Android từ máy Mac.
# Cách dùng:
#   ./restore_all_android.sh                    # Khôi phục tất cả
#   ./restore_all_android.sh com.miui.player    # Khôi phục 1 gói cụ thể
# ==============================================================================

set -u

if ! command -v adb >/dev/null 2>&1; then
    if [ -x "/tmp/adb_work/platform-tools/adb" ]; then
        export PATH="/tmp/adb_work/platform-tools:$PATH"
    else
        echo "[!] Không tìm thấy lệnh adb. Hãy chạy debloat_safe_android.sh trước hoặc cài platform-tools."
        exit 1
    fi
fi

if [ $# -ge 1 ]; then
    PKG="$1"
    echo "[*] Đang khôi phục gói: $PKG ..."
    adb shell "cmd package install-existing $PKG"
    exit 0
fi

ALL_FILE=$(mktemp)
CUR_FILE=$(mktemp)
trap 'rm -f "$ALL_FILE" "$CUR_FILE"' EXIT

adb shell pm list packages -u | sed 's/package://g' | tr -d '\r' | sort > "$ALL_FILE"
adb shell pm list packages    | sed 's/package://g' | tr -d '\r' | sort > "$CUR_FILE"

UNINSTALLED=$(comm -23 "$ALL_FILE" "$CUR_FILE")
if [ -z "$UNINSTALLED" ]; then
    echo "[+] Không có gói nào bị gỡ. Tất cả đã ở trạng thái nguyên bản!"
    exit 0
fi

TOTAL=$(echo "$UNINSTALLED" | wc -l | tr -d ' ')
echo "Tổng số gói đã gỡ tìm thấy: $TOTAL"

COUNT=0
for pkg in $UNINSTALLED; do
    COUNT=$((COUNT + 1))
    printf "[%d/%d] Đang khôi phục %s... " "$COUNT" "$TOTAL" "$pkg"
    out=$(adb shell "cmd package install-existing $pkg" 2>&1 | tr -d '\r')
    if [[ "$out" == *"installed for user"* ]]; then
        echo "OK"
    else
        echo "FAILED ($out)"
    fi
done

echo ""
echo "[*] Đang đưa cài đặt Animation và Background Process Limit về mặc định..."
adb shell "settings put global window_animation_scale 1.0" >/dev/null 2>&1 || true
adb shell "settings put global transition_animation_scale 1.0" >/dev/null 2>&1 || true
adb shell "settings put global animator_duration_scale 1.0" >/dev/null 2>&1 || true
adb shell "device_config delete activity_manager max_cached_processes" >/dev/null 2>&1 || true

echo "==> Hoàn tất khôi phục!"
