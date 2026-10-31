#!/usr/bin/env bash
# ==============================================================================
# MACOS SAFE DEBLOAT, CACHE CLEANUP & PERFORMANCE OPTIMIZER
# Công cụ tối ưu hóa, dọn dẹp bộ nhớ đệm và tăng tốc an toàn cho máy Mac của bạn.
#
# Các bước thực hiện an toàn 100% (không xóa dữ liệu cá nhân hay App Settings):
#   1. Lưu Backup trạng thái LaunchAgents & thông số hệ thống ra ~/Desktop
#   2. Tắt các trình Updater / Telemetry chạy ngầm ngốn RAM/CPU của bên thứ 3
#      (Google Keystone, Adobe CC background, Microsoft AutoUpdate, Spotify/Steam/Zoom daemon...)
#   3. Dọn dẹp bộ nhớ đệm an toàn (~/Library/Caches, Logs, Homebrew cache, Xcode DerivedData)
#   4. Tối ưu tốc độ phản hồi giao diện macOS (Dock nhanh, giảm trễ cửa sổ, tắt quảng cáo Apple)
# ==============================================================================

set -u

echo "=========================================================="
echo "   MACOS SAFE DEBLOAT & OPTIMIZER                         "
echo "=========================================================="

HOST_NAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/Desktop/mac_backup_${HOST_NAME}_${TIMESTAMP}"
mkdir -p "$BACKUP_DIR/LaunchAgents_Disabled"

# ---------- 1. Kiểm tra thông tin máy & Lưu Backup trước khi tối ưu ----------
DISK_FREE_BEFORE=$(df -h / | awk 'NR==2 {print $4}')
CHIP_INFO=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)
RAM_GB=$(( $(sysctl -n hw.memsize) / 1073741824 ))
MACOS_VER=$(sw_vers -productVersion)

echo "[+] Máy Mac   : $HOST_NAME ($CHIP_INFO | RAM: ${RAM_GB}GB | macOS $MACOS_VER)"
echo "[+] Trống đầu : $DISK_FREE_BEFORE"
echo "[+] Thư mục Backup: $BACKUP_DIR"

# Lưu danh sách LaunchAgents & tiến trình đang chạy trước khi can thiệp
ls -la "$HOME/Library/LaunchAgents" > "$BACKUP_DIR/user_launchagents_before.txt" 2>/dev/null || true
ls -la "/Library/LaunchAgents"      > "$BACKUP_DIR/global_launchagents_before.txt" 2>/dev/null || true
ls -la "/Library/LaunchDaemons"     > "$BACKUP_DIR/global_launchdaemons_before.txt" 2>/dev/null || true
ps aux --sort=-%mem 2>/dev/null | head -n 25 > "$BACKUP_DIR/top_mem_before.txt" || ps -Ao user,pid,%cpu,%mem,command -m | head -n 25 > "$BACKUP_DIR/top_mem_before.txt"

# ---------- 2. Vô hiệu hóa các LaunchAgents chạy ngầm gây nặng máy (An toàn) ----------
echo ""
echo "=== BƯỚC 1: TẮT CÁC TIẾN TRÌNH UPDATER / TELEMETRY CHẠY NGẦM ==="

# Danh sách các pattern LaunchAgent của bên thứ 3 thường xuyên chạy ngầm ngốn RAM/CPU
# (Khi mở app chính thì app vẫn chạy bình thường, chỉ tắt tiến trình tự khởi động ngầm cùng macOS)
SAFE_DISABLE_PATTERNS=(
    "com.google.keystone*"                  # Google Chrome Software Update ngầm (rất hay ăn CPU)
    "com.google.GoogleUpdater*"             # Google Updater đời mới
    "com.adobe.GC.*"                        # Adobe Genuine Software Integrity chạy ngầm
    "com.adobe.ARMDC.*"                     # Adobe Acrobat Updater ngầm
    "com.adobe.ccxprocess*"                 # Adobe CCXProcess ngầm
    "com.microsoft.update.agent*"           # Microsoft AutoUpdate chạy ngầm
    "us.zoom.ZoomDaemon*"                   # Zoom background daemon
    "com.valvesoftware.steamclean*"         # Steam background cleaner
    "com.spotify.client.startuphelper*"     # Spotify tự mở ngầm
)

DISABLED_COUNT=0
USER_LA_DIR="$HOME/Library/LaunchAgents"

if [ -d "$USER_LA_DIR" ]; then
    for pattern in "${SAFE_DISABLE_PATTERNS[@]}"; do
        for plist in "$USER_LA_DIR"/$pattern; do
            [ -e "$plist" ] || continue
            plist_name=$(basename "$plist")
            echo "[ĐÃ TẮT NGẦM] $plist_name"
            launchctl bootout "gui/$(id -u)" "$plist" >/dev/null 2>&1 || launchctl unload -w "$plist" >/dev/null 2>&1 || true
            mv "$plist" "$BACKUP_DIR/LaunchAgents_Disabled/$plist_name"
            DISABLED_COUNT=$((DISABLED_COUNT + 1))
        done
    done
fi
echo "==> Đã tắt và dời $DISABLED_COUNT User LaunchAgents rác vào $BACKUP_DIR/LaunchAgents_Disabled/"

# ---------- 3. Dọn dẹp Cache, Logs & File tạm an toàn ----------
echo ""
echo "=== BƯỚC 2: DỌN DẸP BỘ NHỚ ĐỆM (CACHE & LOGS AN TOÀN) ==="

echo "[*] Đang tính toán và dọn ~/Library/Logs & Crash Reports..."
rm -rf "$HOME/Library/Logs/"* 2>/dev/null || true
rm -rf "$HOME/Library/Application Support/CrashReporter/"* 2>/dev/null || true

# Dọn cache các trình duyệt / ứng dụng lớn an toàn (không làm mất đăng nhập hay bookmark)
SAFE_CACHE_DIRS=(
    "$HOME/Library/Caches/Google/Chrome"
    "$HOME/Library/Caches/com.apple.Safari"
    "$HOME/Library/Caches/Mozilla/Firefox"
    "$HOME/Library/Caches/Microsoft Edge"
    "$HOME/Library/Caches/com.spotify.client"
    "$HOME/Library/Caches/CocoaPods"
    "$HOME/Library/Caches/pip"
    "$HOME/Library/Caches/Yarn"
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
)

for cdir in "${SAFE_CACHE_DIRS[@]}"; do
    if [ -d "$cdir" ]; then
        size_human=$(du -sh "$cdir" 2>/dev/null | awk '{print $1}')
        echo "[DỌN CACHE] $cdir ($size_human)"
        rm -rf "${cdir:?}/"* 2>/dev/null || true
    fi
done

# Nếu máy có cài Homebrew thì dọn gói cũ
if command -v brew >/dev/null 2>&1; then
    echo "[*] Phát hiện Homebrew — đang chạy 'brew cleanup --prune=all'..."
    brew cleanup --prune=all -s >/dev/null 2>&1 || true
fi

# ---------- 4. Tinh chỉnh độ mượt giao diện macOS & Tắt Telemetry ----------
echo ""
echo "=== BƯỚC 3: TỐI ƯU ĐỘ MƯỢT GIAO DIỆN & TẮT QUẢNG CÁO APPLE ==="

echo "[*] Tăng tốc độ phản hồi thanh Dock & hiệu ứng cửa sổ..."
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.35
defaults write com.apple.dock expose-animation-duration -float 0.15
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write com.apple.finder DisableAllAnimations -bool true

echo "[*] Tắt gửi dữ liệu phân tích & quảng cáo cá nhân hóa của Apple..."
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Tắt tính năng mở lại các cửa sổ bị treo khi khởi động lại máy
defaults write com.apple.loginwindow TALLogoutSavesState -bool false

# Khởi động lại nhẹ Dock & Finder để áp dụng độ mượt
killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true

DISK_FREE_AFTER=$(df -h / | awk 'NR==2 {print $4}')

# Copy báo cáo vào Clipboard để bạn tiện kiểm tra hoặc lưu trữ
{
    echo "=== MACOS OPTIMIZATION REPORT ==="
    echo "Host: $HOST_NAME | Chip: $CHIP_INFO | RAM: ${RAM_GB}GB | macOS: $MACOS_VER"
    echo "Disk Free: $DISK_FREE_BEFORE -> $DISK_FREE_AFTER"
    echo "Disabled User LaunchAgents: $DISABLED_COUNT"
    echo "=== REMAINING USER LAUNCHAGENTS ==="
    ls -1 "$HOME/Library/LaunchAgents" 2>/dev/null
    echo "=== GLOBAL LAUNCHAGENTS ==="
    ls -1 "/Library/LaunchAgents" 2>/dev/null
    echo "=== TOP RAM PROCESSES ==="
    ps -Ao user,pid,%cpu,%mem,comm -m | head -n 15
} | pbcopy 2>/dev/null && echo "[+] Đã copy Báo cáo sức khỏe máy Mac vào Clipboard (Cmd+V)!"

echo ""
echo "=========================================================="
echo "   HOÀN TẤT TỐI ƯU MACOS!"
echo "   Dung lượng trống: $DISK_FREE_BEFORE  -->  $DISK_FREE_AFTER"
echo "   Thư mục Backup  : $BACKUP_DIR"
echo "=========================================================="
