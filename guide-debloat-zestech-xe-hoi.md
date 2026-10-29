# Hướng dẫn debloat màn hình Zestech (Android car unit) trên macOS

> Dựa trên workflow của [CleanYourTV](https://github.com/Gathin23/cleanyourtv) nhưng **điều chỉnh cho Android car head unit**.  
> Màn hình xe **không phải Android TV** → một số tính năng của repo không áp dụng được.

---

## Điểm khác biệt quan trọng so với Cooca TV

| | Cooca TV (Android TV) | Zestech (Car Android) |
|---|---|---|
| Launcher | Có thể thay thế bằng CleanYourTV launcher | ❌ **Không nên** — launcher gốc gắn với MCU, CAN-bus |
| ADB over WiFi | Bật sẵn hoặc dễ bật | ⚠️ Phải bật thủ công trong Developer Options |
| Port 5555 | Thường mở | Có thể bị chặn bởi firmware xe |
| Debloat | An toàn cao | ⚠️ Cẩn thận với package liên quan đến xe |
| CleanYourTV script | Dùng toàn bộ | Chỉ dùng phần ADB (`disable.sh`, `restore.sh`) |

---

## Yêu cầu

| Thứ | Ghi chú |
|---|---|
| macOS | M1/M2/Intel đều được |
| Homebrew | [brew.sh](https://brew.sh) |
| Màn hình Zestech | Đang boot vào Android bình thường |
| Cùng mạng WiFi | Mac và màn hình phải cùng hotspot/router |

---

## Bước 0 — Cài ADB trên Mac

```bash
brew install android-platform-tools

# Kiểm tra
adb version
```

---

## Bước 1 — Bật Developer Options trên màn hình Zestech

### Cách 1: Qua menu hệ thống chuẩn Android
1. **Cài đặt → Thông tin hệ thống (About)**
2. Bấm vào **"Số bản dựng / Build Number"** 7 lần
3. Quay lại **Cài đặt → Tuỳ chọn nhà phát triển**
4. Bật **USB Debugging**

### Cách 2: Qua Factory Settings (nếu cách 1 không thấy)
Mật khẩu thường gặp: `126`, `3368`, `8888`, `7890`

Sau khi vào Factory Settings, tìm tùy chọn **ADB Debug** hoặc **USB Debug** và bật lên.

---

## Bước 2 — Tìm IP và kết nối ADB qua WiFi

```bash
# Tìm IP của màn hình:
# Cài đặt → WiFi → [Tên mạng] → xem địa chỉ IP

# Connect
adb connect 192.168.1.XXX:5555

# Kiểm tra
adb devices
# Phải thấy: 192.168.1.XXX:5555   device
```

> Nếu màn hình hỏi "Allow USB debugging?" → bấm **Allow**.

---

## Bước 3 — Clone repo và chuẩn bị

```bash
git clone https://github.com/Gathin23/cleanyourtv
cd cleanyourtv

python3 -m venv tools/venv
tools/venv/bin/pip install -r tools/requirements.txt
```

---

## Bước 4 — Khám phá package trên màn hình xe

```bash
export TV_HOST=192.168.1.XXX

# Lấy thông tin hệ thống
tools/venv/bin/python -I tools/tv.py --probe

# Xuất toàn bộ danh sách package
tools/venv/bin/python -I tools/tv.py 'pm list packages' | sort > ~/Desktop/zestech_packages.txt

# Xem app nào đang chạy nền
adb shell ps | grep -v "root\|system"

# Xem app nào tốn RAM nhất
adb shell dumpsys meminfo | head -60
```

---

## Bước 5 — Tạo danh sách debloat cho Zestech

Tạo file `my-zestech-debloat.txt` trong thư mục `cleanyourtv/`:

```
# ===== ZESTECH XPANDER DEBLOAT LIST =====
# Mỗi dòng 1 package name, dòng bắt đầu bằng # là comment
# Chỉ thêm vào đây sau khi đã kiểm tra từng package!

# --- Google bloatware phổ biến (thường an toàn) ---
# com.google.android.videos
# com.google.android.music
# com.google.android.feedback

# --- OEM bloatware (cần kiểm tra từng cái) ---
# com.ten.ung.dung.khong.can

# Hướng dẫn: bỏ dấu # ở đầu dòng để enable disable
```

> ⚠️ **Quy tắc bắt buộc với màn hình xe:**
> - **KHÔNG disable** bất kỳ package nào có tên chứa: `can`, `mcu`, `vehicle`, `car`, `steering`, `camera`, `reverse`, `carlink`
> - **KHÔNG disable** launcher gốc của Zestech — sẽ mất giao diện xe
> - **KHÔNG disable** package liên quan đến Bluetooth car profile

---

## Bước 6 — Chạy debloat

```bash
# Kiểm tra xem package có tồn tại không trước khi disable
adb shell pm list packages | grep "com.ten.muon.tat"

# Disable an toàn (có thể restore)
TV_HOST=192.168.1.XXX tools/disable.sh my-zestech-debloat.txt

# Hoặc disable thủ công từng cái
adb shell pm disable-user --user 0 com.ten.package
```

### Tối ưu thêm bằng ADB (không cần disable package)

```bash
# Giới hạn background processes
adb shell settings put global max_cached_processes 4

# Tắt animation để mượt hơn (0.5x)
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5

# Tắt hoàn toàn animation
# adb shell settings put global window_animation_scale 0
# adb shell settings put global transition_animation_scale 0
# adb shell settings put global animator_duration_scale 0

# Force GPU rendering
adb shell setprop debug.egl.hw 1
```

---

## Bước 7 — Test sau khi debloat

Thực hiện theo thứ tự này (đỗ xe, không test khi đang lái):

- [ ] Camera lùi hiển thị khi gài số R
- [ ] Cảm biến lùi (beep âm thanh)
- [ ] Camera 360 (nếu có)
- [ ] Nút vô-lăng: âm lượng, chuyển bài, nghe/cúp máy
- [ ] Bluetooth kết nối điện thoại
- [ ] Điều hòa (thông tin hiển thị trên màn hình nếu có)
- [ ] GPS / Maps hoạt động bình thường
- [ ] Màn hình khởi động đúng khi bật xe

---

## Bước 8 — Restore nếu có vấn đề

```bash
# Undo toàn bộ list
TV_HOST=192.168.1.XXX tools/restore.sh my-zestech-debloat.txt

# Enable lại 1 package cụ thể
adb shell pm enable com.ten.package.da.tat

# Restore animation settings
adb shell settings put global window_animation_scale 1
adb shell settings put global transition_animation_scale 1
adb shell settings put global animator_duration_scale 1
```

---

## Package cần đặc biệt cẩn thận (KHÔNG disable)

| Package pattern | Lý do |
|---|---|
| `*.launcher*` | Launcher chính — mất là mất giao diện |
| `*.mcu*` | Giao tiếp MCU, CAN-bus |
| `*.carservice*` | Dịch vụ xe |
| `*.canbus*` | CAN-bus decoder |
| `*.camera*`, `*.reverse*` | Camera lùi |
| `*.steering*` | Nút vô-lăng |
| `com.android.systemui` | System UI |
| `com.android.settings` | Cài đặt |
| `android` | Core Android |

---

## Tại sao KHÔNG dùng launcher của CleanYourTV cho xe

Launcher của repo được thiết kế cho **Android TV remote** (D-pad), **không phải touchscreen**. Trên màn hình xe:
- Giao diện sẽ không phù hợp với thao tác chạm
- Launcher gốc Zestech gắn liền với MCU events (bật xe, gài số, v.v.)
- Nếu launcher gốc bị thay thế hoặc disable → có thể mất tích hợp với xe

**Thay vào đó**, nếu muốn launcher đẹp hơn cho màn hình xe, dùng:
- **AGAMA Car Launcher** (trả phí, rất tốt)
- **CarWebGuru Launcher** (miễn phí)
- **Launcher đúng model Zestech** từ nhà sản xuất

---

## Checklist tổng

- [ ] Đã ghi lại IP màn hình
- [ ] ADB connect thành công
- [ ] Đã export danh sách package ra file
- [ ] Đã kiểm tra từng package trước khi thêm vào list
- [ ] Đã chạy debloat
- [ ] Đã test tất cả tính năng xe (camera, nút, BT)
- [ ] File restore.sh sẵn sàng để dùng khi cần
