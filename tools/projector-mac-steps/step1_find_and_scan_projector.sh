#!/usr/bin/env bash
# ==============================================================================
# [STEP 1 - AUTO-DISCOVER & DEEP SCAN ANDROID PROJECTOR] (100% Read-Only)
# Automatically scans your local Wi-Fi subnet for open ADB port 5555 (used by
# Xview Xcine4 Pro / Beecube / OEM Android projectors), connects via ADB,
# backs up package list, and exports a full Markdown report to ~/Desktop + Clipboard.
#
# Usage:
#   ./step1_find_and_scan_projector.sh                 # Auto-find projector IP on Wi-Fi
#   ./step1_find_and_scan_projector.sh 192.168.1.89    # Connect to a specific IP
# ==============================================================================

set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "=========================================================="
echo "   STEP 1: FIND & SCAN ANDROID PROJECTOR (READ-ONLY)      "
echo "=========================================================="

# ---------- 1. Ensure ADB is available ----------
if ! command -v adb >/dev/null 2>&1; then
    WORK_DIR="/tmp/adb_work"
    if [ ! -x "$WORK_DIR/platform-tools/adb" ]; then
        echo "[*] Downloading Google Platform-Tools (adb) for macOS..."
        mkdir -p "$WORK_DIR"
        curl -sL "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip" -o "$WORK_DIR/pt.zip"
        unzip -q -o "$WORK_DIR/pt.zip" -d "$WORK_DIR"
        rm -f "$WORK_DIR/pt.zip"
        chmod +x "$WORK_DIR/platform-tools/adb"
    fi
    export PATH="$WORK_DIR/platform-tools:$PATH"
fi

TARGET_IP="${1:-}"

# ---------- 2. Auto-discover projector IP if not specified ----------
if [ -z "$TARGET_IP" ]; then
    echo "[*] No IP provided. Scanning local Wi-Fi network for open ADB port 5555..."
    FOUND_IPS=$(python3 -c '
import socket
from concurrent.futures import ThreadPoolExecutor

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    s.connect(("8.8.8.8", 80))
    local_ip = s.getsockname()[0]
finally:
    s.close()

subnet = ".".join(local_ip.split(".")[:3])

def check(i):
    ip = f"{subnet}.{i}"
    if ip == local_ip:
        return None
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.25)
    try:
        if sock.connect_ex((ip, 5555)) == 0:
            return ip
    except Exception:
        pass
    finally:
        sock.close()
    return None

with ThreadPoolExecutor(max_workers=64) as ex:
    for res in ex.map(check, range(2, 255)):
        if res:
            print(res)
')

    if [ -z "$FOUND_IPS" ]; then
        echo "[!] Could not find any device with port 5555 open on the current Wi-Fi."
        echo "    -> Make sure the projector is turned ON and connected to the same Wi-Fi,"
        echo "       or pass its IP manually: ./step1_find_and_scan_projector.sh <PROJECTOR_IP>"
        exit 1
    fi

    TARGET_IP=$(echo "$FOUND_IPS" | head -n 1 | tr -d '\r')
    echo "[+] Found open ADB port 5555 at: $TARGET_IP"
fi

# Strip :5555 if user included it
TARGET_IP="${TARGET_IP%%:*}"
DEV="${TARGET_IP}:5555"

echo "[*] Connecting to $DEV..."
ping -c 1 -W 1000 "$TARGET_IP" >/dev/null 2>&1 || true
adb kill-server >/dev/null 2>&1 || true
adb connect "$DEV"

sleep 1
if ! adb devices | grep -q "^${DEV}[[:space:]]*device"; then
    echo "[!] Failed to connect to $DEV (or waiting for authorization on projector screen)."
    adb devices -l
    exit 1
fi

# ---------- 3. Gather Projector Hardware, RAM, Storage & Packages ----------
echo "[*] Reading hardware, RAM, storage, projector services and packages..."

BRAND=$(adb -s "$DEV" shell getprop ro.product.brand | tr -d '\r')
MODEL=$(adb -s "$DEV" shell getprop ro.product.model | tr -d '\r')
DEVICE_CODE=$(adb -s "$DEV" shell getprop ro.product.device | tr -d '\r')
BOARD=$(adb -s "$DEV" shell getprop ro.board.platform | tr -d '\r')
HARDWARE=$(adb -s "$DEV" shell getprop ro.hardware | tr -d '\r')
CPU_ABI=$(adb -s "$DEV" shell getprop ro.product.cpu.abi | tr -d '\r')
ANDROID_VER=$(adb -s "$DEV" shell getprop ro.build.version.release | tr -d '\r')
SDK_VER=$(adb -s "$DEV" shell getprop ro.build.version.sdk | tr -d '\r')
BUILD_ID=$(adb -s "$DEV" shell getprop ro.build.display.id | tr -d '\r')
WM_SIZE=$(adb -s "$DEV" shell wm size 2>/dev/null | tr -d '\r')
WM_DENSITY=$(adb -s "$DEV" shell wm density 2>/dev/null | tr -d '\r')

SAFE_MODEL=$(echo "${MODEL:-Projector}" | tr ' /' '__' | tr -cd '[:alnum:]_-')
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$HOME/Desktop/Projector_${SAFE_MODEL}_packages_backup_${TIMESTAMP}.txt"
REPORT_FILE="$HOME/Desktop/Projector_${SAFE_MODEL}_Step1_Scan.md"

adb -s "$DEV" shell pm list packages -f | tr -d '\r' | sort > "$BACKUP_FILE"

CPU_INFO=$(adb -s "$DEV" shell "cat /proc/cpuinfo | grep -E 'Processor|model name|Hardware|CPU part' | head -n 12" | tr -d '\r')
MEM_INFO=$(adb -s "$DEV" shell "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree'" | tr -d '\r')
STORAGE_DF=$(adb -s "$DEV" shell "df -h /data /system /vendor 2>/dev/null || df -h" | tr -d '\r')
TOP_MEM=$(adb -s "$DEV" shell "dumpsys meminfo | sed -n '/Total PSS by process:/,/Total PSS by OOM adjustment:/p' | head -n 25" | tr -d '\r')
MAX_CACHED=$(adb -s "$DEV" shell "dumpsys activity settings | grep -i cur_max_cached" | tr -d '\r')
ANIM_WIN=$(adb -s "$DEV" shell "settings get global window_animation_scale" | tr -d '\r')
ANIM_TRANS=$(adb -s "$DEV" shell "settings get global transition_animation_scale" | tr -d '\r')
ANIM_DUR=$(adb -s "$DEV" shell "settings get global animator_duration_scale" | tr -d '\r')

USER_PKGS=$(adb -s "$DEV" shell pm list packages -3 | sed 's/package://g' | tr -d '\r' | sort)
ENABLED_PKGS=$(adb -s "$DEV" shell pm list packages -e | sed 's/package://g' | tr -d '\r' | sort)
DISABLED_PKGS=$(adb -s "$DEV" shell pm list packages -d | sed 's/package://g' | tr -d '\r' | sort)
PROJECTOR_PKGS=$(echo "$ENABLED_PKGS" | grep -iE "focus|keystone|projector|zhiying|newlink|sstar|hdmi|source|launcher|cast|miracast|ota" || true)

USER_COUNT=$(echo "$USER_PKGS" | sed '/^$/d' | wc -l | tr -d ' ')
ENABLED_COUNT=$(echo "$ENABLED_PKGS" | sed '/^$/d' | wc -l | tr -d ' ')

# ---------- 4. Write Markdown Report & Copy to Clipboard ----------
cat <<EOF > "$REPORT_FILE"
# Android Projector Scan Report (Step 1 - Scan)

- **Scan Time:** $(date +"%Y-%m-%d %H:%M:%S")
- **Projector IP:** \`$DEV\`
- **Brand / Model:** $BRAND $MODEL (Device: \`$DEVICE_CODE\`)
- **Board / SoC:** \`$BOARD\` / \`$HARDWARE\` (ABI: \`$CPU_ABI\`)
- **Android Version:** Android $ANDROID_VER (SDK $SDK_VER | Build: \`$BUILD_ID\`)
- **Display Resolution:** \`$WM_SIZE\` (\`$WM_DENSITY\`)

## 1. CPU Info
\`\`\`text
$CPU_INFO
\`\`\`

## 2. RAM & Swap Info
\`\`\`text
$MEM_INFO
\`\`\`

## 3. Storage Info
\`\`\`text
$STORAGE_DF
\`\`\`

## 4. Current System Settings
| Setting Key | Current Value |
| :--- | :--- |
| \`window_animation_scale\` | \`$ANIM_WIN\` |
| \`transition_animation_scale\` | \`$ANIM_TRANS\` |
| \`animator_duration_scale\` | \`$ANIM_DUR\` |
| \`max_cached_processes\` | \`$MAX_CACHED\` |

## 5. Top RAM Consuming Processes
\`\`\`text
$TOP_MEM
\`\`\`

## 6. Detected Projector Hardware / Launcher / OTA Packages (Protected Review)
\`\`\`text
$PROJECTOR_PKGS
\`\`\`

## 7. User Installed Apps ($USER_COUNT apps)
\`\`\`text
$USER_PKGS
\`\`\`

## 8. All Enabled Packages ($ENABLED_COUNT packages)
\`\`\`text
$ENABLED_PKGS
\`\`\`

## 9. Disabled Packages
\`\`\`text
$DISABLED_PKGS
\`\`\`
EOF

pbcopy < "$REPORT_FILE" 2>/dev/null || true

echo ""
echo "[OK] EXPORTED .MD REPORT TO DESKTOP & COPIED TO CLIPBOARD (Cmd+V)!"
echo "     Projector      : $BRAND $MODEL ($BOARD / $CPU_ABI / Android $ANDROID_VER)"
echo "     Active Packages: $ENABLED_COUNT (User Apps: $USER_COUNT)"
echo "     Markdown Report: $REPORT_FILE"
echo "     Backup File    : $BACKUP_FILE"
echo "-> Press Cmd+V to paste the report or open $REPORT_FILE on your Desktop!"

