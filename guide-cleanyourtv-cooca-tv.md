# Hướng dẫn dùng CleanYourTV cho Cooca TV (macOS)

> Repo gốc: [github.com/Gathin23/cleanyourtv](https://github.com/Gathin23/cleanyourtv)  
> Cooca TV chạy Android TV → **hoàn toàn tương thích**.

---

## Yêu cầu

| Thứ | Ghi chú |
|---|---|
| macOS | M1/M2/Intel đều được |
| Homebrew | Cài tại [brew.sh](https://brew.sh) nếu chưa có |
| Python 3 | Có sẵn trên macOS, hoặc `brew install python` |
| Java JDK 17–22 | Dùng để build launcher |
| Cooca TV và Mac | **Cùng mạng WiFi** |

---

## Bước 0 — Cài công cụ trên Mac

```bash
# ADB + Android SDK tools
brew install android-commandlinetools

# Java JDK 17
brew install openjdk@17

# Thêm Java vào PATH
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Cài thêm Android SDK platform 34 (cần để build launcher)
sdkmanager "platforms;android-34" "build-tools;34.0.0"
```

---

## Bước 1 — Bật Developer Options trên Cooca TV

1. **Cài đặt → Hệ thống → Giới thiệu (About)**
2. Bấm **OK vào "Build number" 7 lần liên tiếp** → thông báo "Bạn là Developer"
3. Quay lại **Cài đặt → Hệ thống → Tuỳ chọn nhà phát triển (Developer Options)**
4. Bật **USB Debugging**
5. Bật **ADB over Network** (nếu có — tên có thể là "Wireless Debugging" hoặc "Network Debugging")

> ⚠️ Nếu không thấy "ADB over Network", xem Bước 2b bên dưới.

---

## Bước 2 — Kết nối ADB qua WiFi

### 2a. Tìm IP của Cooca TV

**Cài đặt → Mạng → WiFi → [Tên mạng đang kết nối]** → ghi lại địa chỉ IP (ví dụ: `192.168.1.50`)

### 2b. Connect từ Mac

```bash
# Kết nối ADB
adb connect 192.168.1.50:5555

# Kiểm tra kết nối
adb devices
# → Phải thấy: 192.168.1.50:5555   device
```

Khi TV hỏi **"Allow USB debugging?"** → bấm **Allow** (tích vào "Always allow" luôn cho tiện).

> Nếu port 5555 bị từ chối, Cooca TV có thể dùng Wireless Debugging (Android 11+):
> ```bash
> # TV hiện mã ghép đôi (pairing code) trong Developer Options → Wireless Debugging
> adb pair 192.168.1.50:PORT_PAIRING
> # Nhập mã 6 số, sau đó:
> adb connect 192.168.1.50:5555
> ```

---

## Bước 3 — Clone repo CleanYourTV

```bash
git clone https://github.com/Gathin23/cleanyourtv
cd cleanyourtv

# Cài Python dependencies
python3 -m venv tools/venv
tools/venv/bin/pip install -r tools/requirements.txt
```

---

## Bước 4 — Kiểm tra TV

```bash
# Set biến IP (thay bằng IP thật của TV)
export TV_HOST=192.168.1.50

# Xem thông tin TV
tools/venv/bin/python -I tools/tv.py --probe

# Liệt kê tất cả package đang cài
tools/venv/bin/python -I tools/tv.py 'pm list packages' | sort > ~/Desktop/cooca_packages.txt
```

Mở file `cooca_packages.txt` để xem danh sách app trên TV.

---

## Bước 5 — Debloat (2 cách)

### Cách A — Dùng AI assistant (khuyến nghị, dễ nhất)

```bash
# Đọc file PROMPT.md và paste nội dung đó vào Claude / Gemini CLI
cat PROMPT.md
```

Bật **Gemini CLI** hoặc **Claude Code** trong thư mục `cleanyourtv`, paste nội dung PROMPT.md, điền model TV là `Cooca TV` và để AI tự làm.

### Cách B — Tự disable thủ công

```bash
# Xem package nào đang chạy và gây lag
tools/venv/bin/python -I tools/tv.py 'dumpsys activity | grep "cmp="'

# Disable từng package (KHÔNG bị xóa, có thể restore)
adb shell pm disable-user --user 0 com.package.can.xoa

# Hoặc dùng script với file danh sách
# Tạo file my-cooca-debloat.txt với mỗi dòng 1 package name
TV_HOST=192.168.1.50 tools/disable.sh my-cooca-debloat.txt
```

**Ví dụ package thường có thể disable trên Android TV chung:**
```
# Bloatware phổ biến - kiểm tra trước khi disable
com.google.android.videos          # Google TV / Play Movies (nếu không dùng)
com.google.android.music           # Google Play Music (đã khai tử)
com.android.providers.calendar     # Calendar provider (nếu không dùng)
```

> ⚠️ **KHÔNG disable** các package `android`, `com.android.systemui`, `com.android.settings` — có thể brick TV.

---

## Bước 6 — Cài Launcher mới (tuỳ chọn)

Launcher của CleanYourTV trông giống Apple TV, phù hợp với remote TV.

```bash
# Build và cài launcher
export TV_HOST=192.168.1.50
launcher/build-and-install.sh
```

Script tự:
1. Build launcher APK bằng JDK
2. Cài lên TV qua ADB
3. Đặt làm màn hình Home mặc định

---

## Bước 7 — Restore nếu cần

```bash
# Undo toàn bộ debloat list
TV_HOST=192.168.1.50 tools/restore.sh my-cooca-debloat.txt

# Hoặc enable lại từng package
adb shell pm enable com.package.da.disable
```

---

## Checklist nhanh

- [ ] Developer Options đã bật
- [ ] USB Debugging đã bật
- [ ] `adb connect IP:5555` thành công
- [ ] Chạy `--probe` để xem thông tin TV
- [ ] Backup danh sách package trước khi disable
- [ ] Test TV sau khi debloat (app, remote, HDMI)
- [ ] File restore.sh còn đó để dùng khi cần

---

## Tips & Lưu ý

| Tình huống | Xử lý |
|---|---|
| TV mất màn hình Home | `adb shell pm enable com.package.launcher.bi.tat` |
| ADB mất kết nối | `adb connect IP:5555` lại |
| Port 5555 bị đóng | Vào Developer Options → tắt rồi bật lại USB Debugging |
| TV reboot loop | Flash factory reset từ recovery menu |
| Muốn về launcher gốc | `TV_HOST=... tools/restore.sh <danh_sach>` |
