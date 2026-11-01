# Bộ Script Tối Ưu Máy Chiếu Android Qua Wi-Fi Trên macOS (`projector-mac-steps`)

Bộ công cụ 4 bước chạy trực tiếp trên **macOS (MacBook)** giúp tự động dò tìm, kết nối ADB không dây (`port 5555`), quét phần cứng, gỡ bloatware an toàn, cài đặt **SmartTube** (YouTube không quảng cáo) + **TV Bro**, và tối ưu RAM cho các dòng **máy chiếu Android** (như **Xview Xcine4 Pro / Pro2**, **Beecube X2 Max**, **Wanbo**, v.v.).

> **Vì sao không cần tìm chỗ bật Developer Mode trên máy chiếu?**
> Đa số máy chiếu Android OEM (sử dụng giao diện tùy biến `com.zhiying.settings`, `com.oversea.aslauncher`) ẩn menu *Tùy chọn nhà phát triển* trên màn hình cài đặt, nhưng firmware xuất xưởng ở chế độ `userdebug` đã **mở sẵn cổng ADB Wi-Fi `5555`**. Chỉ cần MacBook và máy chiếu kết nối cùng một mạng Wi-Fi là có thể điều khiển và tối ưu ngay.

---

## Chuẩn bị trước khi chạy

1. Bật máy chiếu và kết nối vào **cùng mạng Wi-Fi** với MacBook.
2. Mở ứng dụng **Terminal** trên MacBook và di chuyển vào thư mục chứa script:
   ```bash
   cd /Users/woody/Data/MyProjects/debloat-device/tools/projector-mac-steps
   ```
3. (Tùy chọn) Bạn có thể xem nhanh địa chỉ IP của máy chiếu trong phần **Cài đặt Wi-Fi** trên máy chiếu (ví dụ `192.168.1.xx`), hoặc để script tự động quét toàn bộ mạng LAN.

---

## Quy trình 4 Bước

### Bước 1: Tự động dò IP, kết nối ADB Wi-Fi & Quét toàn diện máy chiếu
```bash
# Cách 1: Tự động quét toàn mạng Wi-Fi trong phòng để tìm máy chiếu mở port 5555
./step1_find_and_scan_projector.sh

# Cách 2: Nếu đã biết IP trên màn hình máy chiếu (nhanh nhất)
./step1_find_and_scan_projector.sh 192.168.1.89
```
- **Tác dụng:**
  - Tự động dò cổng `5555` trên mạng Wi-Fi, kết nối ADB và sao lưu danh sách toàn bộ gói ứng dụng vào thư mục `backups/`.
  - Quét chi tiết Model, vi xử lý (SoC), dung lượng RAM/Swap, bộ nhớ `/data`, các dịch vụ phần cứng máy chiếu (AutoFocus, Keystone, Miracast) và danh sách toàn bộ ứng dụng.
  - Xuất báo cáo `Projector_<Model>_Step1_Scan.md` ra ngoài **Desktop** và tự động **copy vào Clipboard** (`Cmd + V` để dán).

---

### Bước 2: Gỡ Bloatware an toàn & Tự động tải + cài đặt SmartTube, TV Bro
```bash
# Chạy gỡ bloatware mặc định + tự tải và cài SmartTube & TV Bro
./step2_debloat_and_install_apps.sh

# Hoặc gỡ thêm gói chỉ định riêng sau khi xem báo cáo Bước 1:
./step2_debloat_and_install_apps.sh com.example.bloat1 com.example.bloat2

# Nếu chỉ muốn gỡ bloatware mà không tải/cài thêm app:
./step2_debloat_and_install_apps.sh --skip-install
```
- **Cơ chế bảo vệ phần cứng máy chiếu tuyệt đối:**
  - Script có **Danh sách trắng (Protected List)** không bao giờ chạm vào các dịch vụ sống còn của máy chiếu: lấy nét tự động (`autofocus`), căn chỉnh góc chiếu (`keystone`), điều khiển nguồn/quạt (`powerservice`, `systemcontrol`), cổng HDMI (`sourcechange`), Launcher chính (`aslauncher`), và truyền màn hình (`miracast`, `softmedia.receiver`, `newlink.cast`).
- **Tự động dọn dẹp các app rác:**
  - App test nhà máy (`com.newlink.autotest`, `com.newlink.tvtestingtools`), ExoPlayer Demo, bàn phím tiếng Trung Pinyin, Office dùng thử, Nimo TV, và các trình duyệt cũ nặng máy (`BrowseHere`, `Browser`).
- **Tự động nhận diện kiến trúc chip (`armeabi-v7a` / `arm64-v8a`):**
  - Tự tải đúng bản APK **SmartTube** và **TV Bro** mới nhất từ GitHub Releases về cài thẳng vào máy chiếu.

---

### Bước 3: Tối ưu RAM, Bộ nhớ đệm (Cache) & Biên dịch AOT
```bash
# Mặc định giới hạn tối đa 16 tiến trình chạy ngầm (phù hợp máy chiếu 2GB RAM)
./step3_optimize_projector.sh

# Nếu máy chiếu chỉ có 1GB RAM:
./step3_optimize_projector.sh --max-cached 12

# Nếu muốn tăng tốc độ hiệu ứng chuyển cảnh lên 0.5x:
./step3_optimize_projector.sh --fast-anim
```
- **Tác dụng:**
  - Hạ `max_cached_processes` xuống `16` (hoặc `12`), tắt quét ngầm Wi-Fi/BLE.
  - Xả sạch bộ nhớ đệm (`pm trim-caches`) và biên dịch mã máy AOT (`bg-dexopt-job`) giúp mở ứng dụng mượt hơn.

---

### Bước 4: Kiểm tra kết quả, Khôi phục ứng dụng hoặc Ngắt kết nối
```bash
# Kiểm tra dung lượng RAM & bộ nhớ trống sau tối ưu
./step4_verify_or_restore.sh

# Ngắt kết nối ADB Wi-Fi an toàn sau khi hoàn tất
./step4_verify_or_restore.sh --disconnect

# Khôi phục lại 1 ứng dụng bất kỳ nếu cần
./step4_verify_or_restore.sh --restore <ten_package>

# Khôi phục toàn bộ ứng dụng đã gỡ
./step4_verify_or_restore.sh --restore-all
```

