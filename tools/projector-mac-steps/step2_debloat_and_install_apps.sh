#!/usr/bin/env bash
# ==============================================================================
# [STEP 2 - PROJECTOR SAFE DEBLOAT & INSTALL SMARTTUBE + TV BRO]
# Strictly protects projector optical/hardware services (Auto-Focus, Keystone,
# HDMI Source, Miracast/AirPlay, Stock Projector Launcher) while removing safe
# factory test tools, demo apps, Chinese keyboards, and bloatware.
# Optionally downloads and installs SmartTube & TV Bro matched to CPU ABI.
#
# Usage:
#   ./step2_debloat_and_install_apps.sh --dry-run
#   ./step2_debloat_and_install_apps.sh
#   ./step2_debloat_and_install_apps.sh --extra "com.pkg1,com.pkg2"
#   ./step2_debloat_and_install_apps.sh --skip-install
# ==============================================================================

set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/tmp/adb_work/platform-tools:$PATH"

DRY_RUN=0
SKIP_INSTALL=0
EXTRA_PKGS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --skip-install)
            SKIP_INSTALL=1
            shift
            ;;
        --extra)
            EXTRA_PKGS="${2:-}"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

DEV=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
if [ -z "$DEV" ]; then
    echo "[!] No connected projector found in 'adb devices'. Run ./step1_find_and_scan_projector.sh first!"
    exit 1
fi

MODEL=$(adb -s "$DEV" shell getprop ro.product.model | tr -d '\r')
CPU_ABI=$(adb -s "$DEV" shell getprop ro.product.cpu.abi | tr -d '\r')
SAFE_MODEL=$(echo "${MODEL:-Projector}" | tr ' /' '__' | tr -cd '[:alnum:]_-')
REPORT_FILE="$HOME/Desktop/Projector_${SAFE_MODEL}_Step2_Debloat.md"

echo "=========================================================="
echo "   STEP 2: PROJECTOR SAFE DEBLOAT & APP INSTALL           "
echo "   Target: $DEV ($MODEL | ABI: $CPU_ABI)"
if [ "$DRY_RUN" -eq 1 ]; then
    echo "   [DRY-RUN MODE: PREVIEW ONLY, NO CHANGES MADE]          "
fi
echo "=========================================================="

# Hardware / Optical / Cast / Launcher packages that MUST NEVER be removed on a projector
PROTECTED_REGEX="autofocus|keystone|zhiying\.settings|zhiying\.powerservice|newlink\.projector|newlink\.service|newlink\.source|sstar\.systemcontrol|sstar\.sourcechange|sstar\.tv\.inputservice|aslauncher|miracast|newlink\.cast|softmedia\.receiver|btsink"

SAFE_REMOVE_LIST=(
    "com.newlink.autotest|Factory Hardware AutoTest"
    "com.newlink.tvtestingtools|Factory TV Testing Tools"
    "com.google.android.exoplayer2.demo|ExoPlayer Developer Demo App"
    "com.android.inputmethod.pinyin|Chinese Pinyin Input Method"
    "com.mobisystems.editor.office_registered|Preloaded OfficeSuite Bloat"
    "com.tcl.browser|Legacy TCL Browser (Replaced by TV Bro)"
    "org.mozilla.tv.firefox|Discontinued Firefox TV Browser (Replaced by TV Bro)"
    "com.android.egg|Android Easter Egg"
    "com.android.providers.partnerbookmarks|Partner Advertising Bookmarks"
)

if [ -n "$EXTRA_PKGS" ]; then
    IFS=',' read -ra EXTRAS <<< "$EXTRA_PKGS"
    for ep in "${EXTRAS[@]}"; do
        ep_clean=$(echo "$ep" | tr -d ' ')
        [ -n "$ep_clean" ] && SAFE_REMOVE_LIST+=("${ep_clean}|User selected extra package")
    done
fi

INSTALLED_PKGS=$(adb -s "$DEV" shell pm list packages -e | sed 's/package://g' | tr -d '\r')

REMOVED_COUNT=0
SKIPPED_COUNT=0
TABLE_ROWS=""

for entry in "${SAFE_REMOVE_LIST[@]}"; do
    pkg="${entry%%|*}"
    desc="${entry#*|}"

    if echo "$pkg" | grep -qE "$PROTECTED_REGEX"; then
        echo "[PROTECTED] $pkg - Projector critical optical/hardware package kept safe!"
        TABLE_ROWS="${TABLE_ROWS}| \`$pkg\` | **PROTECTED (KEPT)** | $desc |"$'\n'
        continue
    fi

    if ! echo "$INSTALLED_PKGS" | grep -Fxq "$pkg"; then
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[WILL REMOVE] $pkg - $desc"
        TABLE_ROWS="${TABLE_ROWS}| \`$pkg\` | **WILL REMOVE (Dry-Run)** | $desc |"$'\n'
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    else
        out=$(adb -s "$DEV" shell "pm uninstall -k --user 0 $pkg" 2>&1 | tr -d '\r')
        if [[ "$out" == *"Success"* ]]; then
            echo "[REMOVED] $pkg - $desc"
            TABLE_ROWS="${TABLE_ROWS}| \`$pkg\` | **REMOVED (Success)** | $desc |"$'\n'
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        else
            echo "[ERROR]   $pkg : $out"
            TABLE_ROWS="${TABLE_ROWS}| \`$pkg\` | **ERROR ($out)** | $desc |"$'\n'
        fi
    fi
done

INSTALL_SUMMARY="Skipped"
if [ "$DRY_RUN" -eq 0 ] && [ "$SKIP_INSTALL" -eq 0 ]; then
    WORK_APK_DIR="/tmp/projector_apks"
    mkdir -p "$WORK_APK_DIR"

    echo ""
    echo "=== INSTALLING TV BRO & SMARTTUBE (Matched to $CPU_ABI) ==="

    # 1. TV Bro
    if ! echo "$INSTALLED_PKGS" | grep -Fxq "com.phlox.tvwebbrowser"; then
        echo "[*] Downloading & installing TV Bro (Web Browser with remote cursor & adblock)..."
        TVBRO_URL=$(curl -sL https://api.github.com/repos/truefedex/tv-bro/releases/latest | python3 -c 'import sys, json; r=json.load(sys.stdin); print([a["browser_download_url"] for a in r.get("assets",[]) if "generic" in a["name"]][0])')
        curl -sL "$TVBRO_URL" -o "$WORK_APK_DIR/tvbro.apk"
        adb -s "$DEV" install -r "$WORK_APK_DIR/tvbro.apk"
    else
        echo "[+] TV Bro (com.phlox.tvwebbrowser) is already installed."
    fi

    # 2. SmartTube
    if ! echo "$INSTALLED_PKGS" | grep -Fxq "org.smarttube.stable"; then
        echo "[*] Downloading & installing SmartTube ($CPU_ABI)..."
        if [[ "$CPU_ABI" == *"arm64"* ]]; then
            ST_ARCH="arm64-v8a"
        else
            ST_ARCH="armeabi-v7a"
        fi
        ST_URL=$(curl -sL https://api.github.com/repos/yuliskov/SmartTube/releases/latest | python3 -c "import sys, json; r=json.load(sys.stdin); print([a['browser_download_url'] for a in r.get('assets',[]) if '$ST_ARCH' in a['name']][0])")
        curl -sL "$ST_URL" -o "$WORK_APK_DIR/smarttube.apk"
        adb -s "$DEV" install -r "$WORK_APK_DIR/smarttube.apk"
    else
        echo "[+] SmartTube (org.smarttube.stable) is already installed."
    fi
    INSTALL_SUMMARY="Installed SmartTube & TV Bro ($CPU_ABI)"
fi

[ -z "$TABLE_ROWS" ] && TABLE_ROWS="| *(No matching bloatware packages found)* | - | - |"$'\n'

cat <<EOF > "$REPORT_FILE"
# Android Projector Debloat & App Install Report (Step 2)

- **Time:** $(date +"%Y-%m-%d %H:%M:%S")
- **Projector:** $MODEL (\`$DEV\` | ABI: \`$CPU_ABI\`)
- **Debloat Summary:** Processed **$REMOVED_COUNT packages** | Skipped **$SKIPPED_COUNT not installed**
- **Apps Installed:** $INSTALL_SUMMARY

## Package Action Details
| Package ID | Status | Description |
| :--- | :--- | :--- |
$TABLE_ROWS
EOF

pbcopy < "$REPORT_FILE" 2>/dev/null || true

echo ""
echo "[OK] STEP 2 COMPLETE! Exported to $REPORT_FILE and copied to Clipboard (Cmd+V)!"

