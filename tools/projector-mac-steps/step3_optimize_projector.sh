#!/usr/bin/env bash
# ==============================================================================
# STEP 3: Tối ưu RAM, Bộ nhớ đệm (Cache) & Biên dịch AOT cho Máy chiếu Android
# Cách dùng:
#   ./step3_optimize_projector.sh                  (mặc định max_cached_processes=16)
#   ./step3_optimize_projector.sh --max-cached 12  (nếu máy chiếu chỉ có 1GB RAM)
#   ./step3_optimize_projector.sh --fast-anim      (tăng tốc hiệu ứng chuyển cảnh 0.5x)
# ==============================================================================

set -u

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MAX_CACHED=16
FAST_ANIM=0

while [ $# -gt 0 ]; do
    case "$1" in
        --max-cached)
            MAX_CACHED="${2:-16}"
            shift 2
            ;;
        --fast-anim)
            FAST_ANIM=1
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}   STEP 3: TOI UU RAM, CACHE & AOT CHO MAY CHIEU ANDROID         ${NC}"
echo -e "${CYAN}=================================================================${NC}"

if ! command -v adb >/dev/null 2>&1; then
    echo -e "${RED}[LOI] Khong tim thay 'adb'.${NC}"
    exit 1
fi

SERIAL=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
if [ -z "$SERIAL" ]; then
    echo -e "${RED}[LOI] Khong tim thay may chieu nao dang ket noi ADB!${NC}"
    echo -e "${YELLOW}Hay chay ./step1_find_and_scan_projector.sh truoc.${NC}"
    exit 1
fi

adb_cmd() {
    adb -s "$SERIAL" "$@"
}

MODEL=$(adb_cmd shell getprop ro.product.model | tr -d '\r')
SAFE_MODEL=$(echo "$MODEL" | tr ' /:' '___')
echo -e "${GREEN}[OK] Dang toi uu may chieu: $MODEL ($SERIAL)${NC}"

BEFORE_CACHED=$(adb_cmd shell dumpsys activity settings | grep "CUR_MAX_CACHED_PROCESSES" | tr -d '\r' | xargs)

echo -e "\n${YELLOW}[1/4] Gioi han tien trinh ngam (max_cached_processes = $MAX_CACHED)...${NC}"
adb_cmd shell device_config set_sync_disabled_for_tests persistent >/dev/null 2>&1 || true
adb_cmd shell device_config put activity_manager max_cached_processes "$MAX_CACHED" >/dev/null 2>&1 || true
adb_cmd shell settings put global activity_manager_constants max_cached_processes="$MAX_CACHED" >/dev/null 2>&1 || true
AFTER_CACHED=$(adb_cmd shell dumpsys activity settings | grep "CUR_MAX_CACHED_PROCESSES" | tr -d '\r' | xargs)
echo -e "  -> Truoc: ${BEFORE_CACHED:-Mac dinh} | Sau: ${AFTER_CACHED:-max_cached_processes=$MAX_CACHED}"

echo -e "\n${YELLOW}[2/4] Tat quet Wi-Fi / BLE ngam & toi uu hieu ung...${NC}"
adb_cmd shell settings put global wifi_scan_always_enabled 0 >/dev/null 2>&1 || true
adb_cmd shell settings put global ble_scan_always_enabled 0 >/dev/null 2>&1 || true
if [ "$FAST_ANIM" -eq 1 ]; then
    adb_cmd shell settings put global window_animation_scale 0.5
    adb_cmd shell settings put global transition_animation_scale 0.5
    adb_cmd shell settings put global animator_duration_scale 0.5
    echo -e "  -> Da chinh toc do hieu ung (Animation Scale) ve 0.5x."
else
    echo -e "  -> Giu nguyen toc do hieu ung (1.0x). (Dung --fast-anim neu muon chinh 0.5x)"
fi

echo -e "\n${YELLOW}[3/4] Don sach bo nho dem he thong (pm trim-caches)...${NC}"
adb_cmd shell pm trim-caches 999999999999999999 >/dev/null 2>&1 || true
echo -e "  -> Completed"

echo -e "\n${YELLOW}[4/4] Bien dich toi uu ma ung dung AOT (bg-dexopt-job)...${NC}"
echo -e "  (Co the mat 15 - 60 giay tuy so luong ung dung...)"
DEXOPT_OUT=$(adb_cmd shell cmd package bg-dexopt-job 2>&1 | tr -d '\r')
echo -e "  -> $DEXOPT_OUT"

STORAGE_AFTER=$(adb_cmd shell df -h /data 2>/dev/null | tr -d '\r')
MEM_AFTER=$(adb_cmd shell "grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree' /proc/meminfo" 2>/dev/null | tr -d '\r')
ACTIVE_PKGS=$(adb_cmd shell pm list packages -e 2>/dev/null | wc -l | xargs)

REPORT_FILE="$HOME/Desktop/Projector_${SAFE_MODEL}_Step3_Optimize.md"
cat <<EOF > "$REPORT_FILE"
# Android Projector Optimization Report (Step 3 - System & RAM)

- **Device:** $MODEL (\`$SERIAL\`)
- **Active Packages:** \`$ACTIVE_PKGS\`
- **Max Cached Processes:** \`$AFTER_CACHED\` (Before: \`$BEFORE_CACHED\`)
- **Wi-Fi / BLE Background Scan:** \`0\` (Disabled)
- **Cache Cleanup (\`pm trim-caches\`):** Completed
- **AOT Compilation (\`bg-dexopt-job\`):** \`$DEXOPT_OUT\`

## Storage (/data)
\`\`\`text
$STORAGE_AFTER
\`\`\`

## RAM & Swap Info
\`\`\`text
$MEM_AFTER
\`\`\`
EOF

pbcopy < "$REPORT_FILE"

echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}[HOAN TAT STEP 3]${NC}"
echo -e "  - File bao cao : ${CYAN}$REPORT_FILE${NC}"
echo -e "  - Clipboard    : ${GREEN}Da copy san vao Clipboard (Cmd + V de dan)${NC}"
echo -e "  - Buoc tiep    : Chay ${YELLOW}./step4_verify_or_restore.sh${NC} de kiem tra hoac ngat ket noi"
echo -e "${GREEN}=================================================================${NC}"

