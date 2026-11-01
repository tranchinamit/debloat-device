#!/usr/bin/env bash
# ==============================================================================
# STEP 4: Kiểm tra trạng thái sau tối ưu, Khôi phục ứng dụng hoặc Ngắt kết nối ADB
# Cách dùng:
#   ./step4_verify_or_restore.sh                      (Kiểm tra RAM/Storage & xuất báo cáo)
#   ./step4_verify_or_restore.sh --disconnect         (Ngắt kết nối ADB Wi-Fi an toàn)
#   ./step4_verify_or_restore.sh --restore <package>  (Khôi phục 1 ứng dụng đã gỡ)
#   ./step4_verify_or_restore.sh --restore-all        (Khôi phục toàn bộ ứng dụng đã gỡ)
# ==============================================================================

set -u

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"

if ! command -v adb >/dev/null 2>&1; then
    echo -e "${RED}[LOI] Khong tim thay 'adb'.${NC}"
    exit 1
fi

if [ "${1:-}" = "--disconnect" ]; then
    echo -e "${YELLOW}[*] Dang ngat ket noi ADB Wi-Fi va tat ADB server...${NC}"
    adb disconnect
    adb kill-server
    echo -e "${GREEN}[OK] Da ngat ket noi hoan toan voi may chieu!${NC}"
    exit 0
fi

SERIAL=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
if [ -z "$SERIAL" ]; then
    echo -e "${RED}[LOI] Khong tim thay may chieu nao dang ket noi ADB!${NC}"
    exit 1
fi

adb_cmd() {
    adb -s "$SERIAL" "$@"
}

MODEL=$(adb_cmd shell getprop ro.product.model | tr -d '\r')
SAFE_MODEL=$(echo "$MODEL" | tr ' /:' '___')

if [ "${1:-}" = "--restore" ] && [ -n "${2:-}" ]; then
    PKG="$2"
    echo -e "${YELLOW}[*] Dang khoi phuc goi: $PKG tren $MODEL...${NC}"
    adb_cmd shell cmd package install-existing "$PKG"
    adb_cmd shell pm enable "$PKG" >/dev/null 2>&1 || true
    exit 0
fi

if [ "${1:-}" = "--restore-all" ]; then
    LATEST_REMOVED=$(ls -t "$BACKUP_DIR"/removed_packages_*.txt 2>/dev/null | head -n 1 || true)
    if [ -z "$LATEST_REMOVED" ]; then
        echo -e "${RED}[LOI] Khong tim thay file danh sach goi da go trong $BACKUP_DIR${NC}"
        exit 1
    fi
    echo -e "${YELLOW}[*] Dang khoi phuc tat ca goi tu: $LATEST_REMOVED${NC}"
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        echo -ne "  - Khoi phuc $pkg ... "
        adb_cmd shell cmd package install-existing "$pkg"
    done < "$LATEST_REMOVED"
    echo -e "${GREEN}[OK] Da khoi phuc xong!${NC}"
    exit 0
fi

echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}   STEP 4: KIEM TRA TONG KET MAY CHIEU ANDROID ($MODEL)          ${NC}"
echo -e "${CYAN}=================================================================${NC}"

ACTIVE_PKGS=$(adb_cmd shell pm list packages -e 2>/dev/null | wc -l | xargs)
USER_PKGS=$(adb_cmd shell pm list packages -3 2>/dev/null | tr -d '\r' | sed 's/^package://' | sort)
MAX_CACHED=$(adb_cmd shell dumpsys activity settings | grep "CUR_MAX_CACHED_PROCESSES" | tr -d '\r' | xargs)
STORAGE_INFO=$(adb_cmd shell df -h /data 2>/dev/null | tr -d '\r')
MEM_INFO=$(adb_cmd shell "grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree' /proc/meminfo" 2>/dev/null | tr -d '\r')
TOP_RAM=$(adb_cmd shell dumpsys meminfo 2>/dev/null | awk '/Total PSS by process:/{flag=1; next} /Total PSS by OOM adjustment:/{flag=0} flag' | head -n 18 | tr -d '\r')

REPORT_FILE="$HOME/Desktop/Projector_${SAFE_MODEL}_Step4_Verify.md"
cat <<EOF > "$REPORT_FILE"
# Android Projector Final Verification Report (Step 4)

- **Verify Time:** $(date '+%Y-%m-%d %H:%M:%S')
- **Device:** $MODEL (\`$SERIAL\`)
- **Active System + User Packages:** \`$ACTIVE_PKGS\`
- **Max Cached Processes:** \`$MAX_CACHED\`

## 1. Storage (/data)
\`\`\`text
$STORAGE_INFO
\`\`\`

## 2. RAM & Swap Info
\`\`\`text
$MEM_INFO
\`\`\`

## 3. Top RAM Consuming Processes
\`\`\`text
$TOP_RAM
\`\`\`

## 4. Installed Third-Party Apps
\`\`\`text
$USER_PKGS
\`\`\`
EOF

pbcopy < "$REPORT_FILE"

echo -e "${GREEN}[HOAN TAT KIEM TRA]${NC}"
echo -e "  - Bao cao luu tai : ${CYAN}$REPORT_FILE${NC}"
echo -e "  - Clipboard       : ${GREEN}Da copy san vao Clipboard (Cmd + V de dan)${NC}"
echo -e "  - Ngat ket noi    : Chay ${YELLOW}./step4_verify_or_restore.sh --disconnect${NC} khi da xong"

