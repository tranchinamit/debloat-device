# Kế hoạch debloat Redmi Note 4

> [!NOTE]
> Redmi Note 4 có 2 phiên bản: **Snapdragon 625 (codename `mido`)** – bản phổ biến, có nhiều ROM custom; và **MediaTek Helio X20 (`nikel`)** – ít ROM hơn. Kiểm tra bản của bạn ở Giai đoạn 0. Máy đã cũ (ra mắt 2016), thường dừng ở MIUI 10/Android 7–8, nên ROM custom là cách làm máy nhẹ hơn nhiều.

## Giai đoạn 0 – Kiểm tra máy
1. Settings → About phone: ghi lại phiên bản MIUI, Android, RAM/ROM (2/3/4GB).
2. Xác định chip: Snapdragon hay MediaTek (ví dụ dùng app CPU-Z hoặc `adb shell getprop ro.product.device` → `mido` hoặc `nikel`).
3. Bật Developer options: bấm "MIUI version" 7 lần. Bật **USB debugging** và **USB debugging (Security settings)**, cần đăng nhập Mi Account.
4. Trên Mac, tải platform-tools (không cần cài):
   ```
   cd ~/Downloads
   curl -O https://dl.google.com/android/repository/platform-tools-latest-darwin.zip
   unzip platform-tools-latest-darwin.zip
   cd platform-tools
   ./adb devices
   ```
   Chọn "File transfer" khi cắm USB, bấm cho phép trên máy.

## Giai đoạn 1 – Backup
1. Ảnh/video/file: chép sang Mac hoặc Google Photos.
2. Danh bạ, tin nhắn, ứng dụng: Google backup + Mi Cloud.
3. Lưu danh sách app gốc:
   ```
   ./adb shell pm list packages -f > packages_goc.txt
   ```
4. Ghi lại tài khoản đang đăng nhập, 2FA (Authenticator) trước khi thay đổi.

## Giai đoạn 2 – Debloat không root (rủi ro thấp, làm trước)
Gỡ app cho user 0, khôi phục được bằng `cmd package install-existing`:
```
./adb shell pm uninstall -k --user 0 <package>
./adb shell cmd package install-existing <package>
```

**Có thể gỡ (đã thử phổ biến trên MIUI):**
| Nhóm | Package |
|---|---|
| Quảng cáo/phân tích | `com.miui.analytics`, `com.miui.msa.global`, `com.xiaomi.joyose` |
| App Xiaomi thừa | `com.miui.videoplayer`, `com.miui.player`, `com.miui.weather2`, `com.miui.notes`, `com.miui.bugreport`, `com.miui.hybrid` |
| Mi Cloud/dịch vụ | `com.miui.cloudservice`, `com.miui.cloudbackup`, `com.xiaomi.mipicks`, `com.mi.globalbrowser` |
| Google không dùng | `com.google.android.videos`, `com.google.android.music`, `com.google.android.apps.tachyon` |
| Facebook/bundled | `com.facebook.appmanager`, `com.facebook.services`, `com.facebook.system` |

**Không gỡ:** `com.android.systemui`, `com.miui.home`, `com.android.phone`, `com.android.providers.*`, `com.google.android.gms`, `com.android.settings`, `com.miui.securitycenter` (cẩn trọng), `com.android.vending`.

Quy trình: gỡ **3–5 app mỗi lần** → khởi động lại → kiểm tra gọi, SMS, Wi-Fi, camera, sạc.

Cài launcher nhẹ: *Lawnchair* / *Niagara* / *Nova* – đặt làm mặc định.

Tối ưu thêm:
```
./adb shell settings put global window_animation_scale 0.5
./adb shell settings put global transition_animation_scale 0.5
./adb shell settings put global animator_duration_scale 0.5
```
Tắt MSA quảng cáo: Settings → Passwords & security → Authorization & revocation → msa; tắt "Personalized ad recommendations" và "Auto-update apps".

## Giai đoạn 3 – ROM custom (làm nhẹ & mượt nhất, rủi ro trung bình)
> [!WARNING]
> Mở bootloader **xóa toàn bộ dữ liệu** và chỉ làm được khi tài khoản Mi đủ điều kiện chờ (thường 72 giờ trở lên). Công cụ **Mi Unlock chỉ có bản Windows**, nên bước mở khóa phải làm trên máy Windows. Các bước còn lại (fastboot, adb) làm được trên Mac.

1. Đăng nhập Mi Account trên máy → Developer options → **Mi Unlock status** → Add account and device. Chờ hết thời gian.
2. Dùng Mi Unlock (Windows) để mở bootloader. Máy ở chế độ fastboot (Vol- + Power).
3. Tải ROM phù hợp bản `mido`: LineageOS, crDroid, Pixel Experience, Evolution X…, bản dựa Android 10–13 tùy ROM. Kiểm tra trên XDA, lineageos.org hoặc Telegram nhóm `mido`. Kèm `recovery` (TWRP/OrangeFox/Lineage Recovery) và GApps (MindTheGapps) nếu ROM không kèm.
4. Flash recovery bằng fastboot (làm được trên Mac):
   ```
   ./fastboot flash recovery recovery.img
   ./fastboot reboot recovery
   ```
5. Trong recovery: backup `boot`, `system`, `data` (nếu dùng TWRP) vào thẻ SD/USB-OTG → Wipe data → Sideload ROM → Sideload GApps (nếu cần) → Reboot.
6. Với ROM Android mới hơn, máy 2–3GB RAM có thể chậm; ưu tiên ROM nhẹ (LineageOS bản Android 10/11, hoặc AOSP/AOSPA thuần).

## Giai đoạn 4 – Cứu máy khi lỗi
- Bootloop sau debloat: vào recovery (Vol+ + Power) → Wipe data/factory reset, hoặc `adb shell cmd package install-existing` các package đã gỡ.
- Flash lại ROM gốc: tải **Fastboot ROM** MIUI chính thức cho `mido`, flash bằng **Mi Flash Tool (Windows)** hoặc script `flash_all.sh` (Mac/Linux) từ trong ROM, cần bootloader đã mở.

## Checklist sau khi hoàn tất
- [ ] Gọi/SMS, 4G, Wi-Fi, Bluetooth
- [ ] Camera, đèn flash, vân tay
- [ ] Sạc, pin, nhiệt độ
- [ ] Âm thanh, GPS, thông báo ứng dụng quan trọng (ngân hàng, Zalo)

## Đề xuất lộ trình
1. Giai đoạn 0 + 1 ngay hôm nay.
2. Giai đoạn 2 – xong sau 30–60 phút, đã đủ nhẹ nếu chỉ cần máy sạch hơn.
3. Giai đoạn 3 chỉ khi vẫn thấy chậm. Khởi động thủ tục mở khóa bootloader sớm vì có thời gian chờ.

## Cần bạn cung cấp
- Phiên bản MIUI, Android, RAM, codename (`mido`/`nikel`).
- File `packages_goc.txt` – tôi sẽ lọc danh sách gỡ phù hợp.
