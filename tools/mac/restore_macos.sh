#!/usr/bin/env bash
# ==============================================================================
# RESTORE MACOS SETTINGS & LAUNCHAGENTS
# Khôi phục lại hiệu ứng mặc định của macOS và phục hồi các LaunchAgents đã tắt.
# Cách dùng:
#   ./restore_macos.sh [đường_dẫn_thư_mục_backup]
# ==============================================================================

set -u

echo "[*] Đang khôi phục cài đặt hiệu ứng giao diện macOS về mặc định..."
defaults delete com.apple.dock autohide-delay 2>/dev/null || true
defaults delete com.apple.dock autohide-time-modifier 2>/dev/null || true
defaults delete com.apple.dock expose-animation-duration 2>/dev/null || true
defaults delete NSGlobalDomain NSAutomaticWindowAnimationsEnabled 2>/dev/null || true
defaults delete NSGlobalDomain NSWindowResizeTime 2>/dev/null || true
defaults delete com.apple.finder DisableAllAnimations 2>/dev/null || true
defaults delete com.apple.LaunchServices LSQuarantine 2>/dev/null || true

killall Dock >/dev/null 2>&1 || true
killall Finder >/dev/null 2>&1 || true
echo "[+] Đã khôi phục hiệu ứng Dock, Finder và Cửa sổ về mặc định."

if [ $# -ge 1 ] && [ -d "$1/LaunchAgents_Disabled" ]; then
    BACKUP_LA="$1/LaunchAgents_Disabled"
    echo "[*] Đang khôi phục các LaunchAgents từ: $BACKUP_LA"
    mkdir -p "$HOME/Library/LaunchAgents"
    for plist in "$BACKUP_LA"/*.plist; do
        [ -e "$plist" ] || continue
        plist_name=$(basename "$plist")
        mv "$plist" "$HOME/Library/LaunchAgents/$plist_name"
        launchctl load -w "$HOME/Library/LaunchAgents/$plist_name" >/dev/null 2>&1 || true
        echo "    -> Đã khôi phục: $plist_name"
    done
fi

echo "==> Hoàn tất khôi phục macOS!"
