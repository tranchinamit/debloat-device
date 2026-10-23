# Kế hoạch backup & làm nhẹ OS – Xview Xcine4 Pro2

> [!IMPORTANT]
> Máy chiếu dùng Android/Google TV tùy biến của hãng, SoC (nhiều khả năng Amlogic/MediaTek/Allwinner – **chưa xác minh**). Hiện **không có ROM custom công khai**. ROM Android TV chung sẽ làm hỏng auto-focus, keystone, remote, Wi-Fi. Vì vậy kế hoạch có 3 mức, đi từ an toàn đến rủi ro.

## Giai đoạn 0 – Xác định phần cứng (bắt buộc)
1. Bật Developer options: Settings → About → bấm "Build number" 7 lần.
2. Bật USB debugging + Wireless debugging (hoặc ADB qua mạng).
3. Cài [platform-tools](https://developer.android.com/tools/releases/platform-tools) trên PC, rồi chạy:
   ```
   cd ~/Downloads
   curl -O https://dl.google.com/android/repository/platform-tools-latest-darwin.zip
   unzip platform-tools-latest-darwin.zip
   cd platform-tools
   
   ./adb connect <IP_máy_chiếu>:5555
   ./adb shell getprop ro.board.platform

   adb connect <IP_máy_chiếu>:5555
   adb shell getprop ro.board.platform
   adb shell getprop ro.product.board
   adb shell getprop ro.build.fingerprint
   adb shell getprop ro.boot.hardware
   adb shell cat /proc/cpuinfo
   adb shell getprop ro.build.version.release
   adb shell getprop ro.oem_unlock_supported
   adb shell df -h
   ```
4. Ghi lại: chip, RAM/ROM, bản Android, tên model chính xác (Settings → About), bản firmware.
5. Hỏi hãng (Xview VN, hotline/Zalo) xin **file firmware gốc + tool flash** → cách backup an toàn nhất.

## Giai đoạn 1 – Backup (làm trước mọi thay đổi)
| Mức | Cách | Yêu cầu | Ghi chú |
|---|---|---|---|
| A | Backup app + dữ liệu bằng `adb backup`/Swift Backup, ghi danh sách package | Không root | Chỉ backup user data, không phải OS |
| B | Xin firmware chính hãng (.img/.zip) | Liên hệ hãng | Dùng để khôi phục khi lỗi |
| C | Dump full eMMC | Root hoặc chế độ USB-burn (Amlogic: *USB Burning Tool*, MTK: *SP Flash Tool*, Allwinner: *PhoenixSuit*) | Cần tool đúng chip, có UART/short eMMC nếu máy khóa |

Lưu lại trước: `adb shell pm list packages -f > packages_goc.txt`, `adb shell settings list global/secure/system`, ảnh chụp các cài đặt ảnh/âm thanh/keystone.

> [!WARNING]
> Không flash gì khi chưa có **bản backup/firmware gốc** và chưa test được chế độ recovery/burn của máy.

## Giai đoạn 2 – Làm nhẹ OS không cần root (khuyến nghị, rủi ro thấp)
1. **Gỡ bloatware cho user 0** (khôi phục được):
   ```
   adb shell pm uninstall -k --user 0 <package>
   adb shell cmd package install-existing <package>   # khôi phục
   ```
   Hoặc `pm disable-user --user 0 <package>`.
2. Lập danh sách từ `packages_goc.txt`, phân loại: **giữ** (system UI, framework, keystone/focus, remote, Wi-Fi, bluetooth, Google Play services), **gỡ** (app quảng cáo, tiện ích hãng, store/cast thừa, OTA nếu muốn chặn cập nhật). Gỡ từng nhóm nhỏ, reboot kiểm tra.
3. **Launcher đơn giản**: cài *Projectivy Launcher* / *FLauncher* / *Wolf Launcher*; đặt làm mặc định (có thể cần ADB: `adb shell pm disable-user --user 0 <launcher_gốc>`).
4. **Tăng độ mượt**:
   ```
   adb shell settings put global window_animation_scale 0.5
   adb shell settings put global transition_animation_scale 0.5
   adb shell settings put global animator_duration_scale 0.5
   ```
   Giới hạn background process (Developer options), tắt app tự khởi động, dùng ứng dụng nhẹ (SmartTube, VLC, Kodi lite).
5. Dọn dung lượng: xóa cache, giữ trống ≥ 25% bộ nhớ.

## Giai đoạn 3 – Cài OS mới (chỉ khi đã có đủ điều kiện)
Điều kiện: biết chip, có firmware gốc, có công cụ burn, có đường khôi phục.
- **Hướng 1 (an toàn nhất):** Flash lại firmware gốc đã debloat (repack bằng tool của chip) – giữ driver focus/keystone.
- **Hướng 2:** Tìm ROM của box/projector **cùng board** (cùng SoC, cùng DDR/eMMC, cùng panel/dtb) trên XDA/4PDA/freaktab. Phải kiểm tra dtb, driver motor focus.
- **Hướng 3 (không khuyến nghị):** AOSP/LineageOS tự build – cần kernel source của hãng (yêu cầu theo GPL), tốn nhiều thời gian.

Quy trình flash chung: sạc/cắm nguồn ổn định → cài driver USB → vào chế độ burn → nạp firmware → factory reset → kiểm tra Wi-Fi/BT/remote/focus/keystone/HDMI/audio.

## Kiểm tra sau cùng
- [ ] Auto-focus, keystone, hình ảnh, âm thanh, HDMI-CEC
- [ ] Wi-Fi/Bluetooth/remote, Netflix/YouTube (DRM Widevine L1/L3)
- [ ] Nhiệt độ quạt, thời gian boot

## Đề xuất lộ trình
1. Giai đoạn 0 + 1A/1B ngay hôm nay.
2. Giai đoạn 2 (debloat + launcher) – thường đạt 80% mục tiêu "nhẹ, mượt, đơn giản".
3. Chỉ xem xét Giai đoạn 3 nếu có firmware/tool từ hãng.

## Cần bạn cung cấp
- Kết quả các lệnh `getprop` ở Giai đoạn 0 và danh sách `pm list packages`.
- Phiên bản Android và firmware hiện tại.
