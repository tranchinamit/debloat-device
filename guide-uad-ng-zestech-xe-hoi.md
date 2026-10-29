# Hướng dẫn dùng UAD-ng để debloat màn hình Zestech (Android car unit) trên macOS

> Repo UAD-ng: [github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation)  
> UAD-ng **không có profile riêng cho Android car head unit** → cần dùng ở chế độ manual.  
> Ưu điểm so với ADB thuần: có GUI, search dễ, thấy mô tả package, restore 1 click.

---

## Lưu ý quan trọng trước khi bắt đầu

> ⚠️ UAD-ng được design cho **điện thoại và tablet Android**. Zestech là **Android car unit** — không có profile cụ thể trong database của UAD-ng. Bạn phải tự đánh giá từng package.

> ⚠️ **KHÔNG** dùng tính năng "Auto debloat" hay "Select all Recommended" trên màn hình xe — các package "Recommended to remove" trên điện thoại có thể là **critical** trên car unit.

> ✅ UAD-ng vẫn hữu ích vì: GUI search, restore 1 click, và mô tả package giúp bạn hiểu từng app.

---

## Bước 0 — Chuẩn bị công cụ trên Mac

### 1. Cài ADB (Android Platform-Tools)
UAD-ng cần lệnh `adb` để giao tiếp với màn hình xe. Bạn không cần cài toàn bộ Android SDK, chỉ cần cài gói **Platform-Tools** siêu nhẹ:

```bash
# Cài qua Homebrew
brew install android-platform-tools

# Kiểm tra
adb version
```

### 2. Tải và chạy UAD-ng
1. Vào [Releases page](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/latest)
2. Download:
   - **Apple Silicon (M1/M2/M3):** `uad_ng-macos-apple-silicon.tar.gz`
   - **Intel Mac:** `uad_ng-macos-x86_64.tar.gz`
3. Giải nén và chạy:

```bash
cd ~/Downloads
tar -xzf uad_ng-macos-*.tar.gz
chmod +x uad_ng
./uad_ng
```

> Nếu macOS chặn: **System Settings → Privacy & Security → Allow Anyway**

---

## Bước 1 — Bật Developer Options trên màn hình Zestech

### Cách thường (Android chuẩn)
1. **Cài đặt → Thông tin hệ thống (About)**
2. Bấm **"Số bản dựng / Build Number"** 7 lần
3. **Cài đặt → Tuỳ chọn nhà phát triển**
4. Bật **USB Debugging**

### Nếu không tìm thấy Developer Options
Thử qua **Factory Settings** (mật khẩu: `126`, `3368`, `8888`, `7890`):
- Tìm tùy chọn **ADB Debug** hoặc **USB Debug** và bật lên

---

## Bước 2 — Kết nối qua WiFi (khuyến nghị — không cần cáp)

```bash
# Tìm IP của màn hình: Cài đặt → WiFi → [Tên mạng] → xem IP

# Kết nối ADB WiFi
adb connect 192.168.1.XXX:5555

# Verify
adb devices
# Phải thấy: 192.168.1.XXX:5555   device
```

Màn hình hỏi "Allow USB debugging?" → bấm **Allow**.

---

## Bước 3 — Mở UAD-ng — chế độ thủ công cho car unit

1. Mở `uad_ng`
2. UAD-ng tự detect thiết bị qua ADB (kể cả WiFi ADB)
3. Thiết bị Zestech sẽ hiện nhưng **không có brand profile cụ thể** → hiện dưới dạng generic Android

### Giao diện UAD-ng với Zestech

```
Brand filter: [All] ← để "All", không có "Zestech" hay "Car"
Search: [tìm theo tên package]
Package list: danh sách tất cả app trên màn hình
```

---

## Bước 4 — Workflow debloat an toàn cho Zestech

### Nguyên tắc vàng: Chỉ xóa những gì BẠN BIẾT chắc

Khác với điện thoại, trên màn hình xe **KHÔNG** áp dụng logic:
- ~~"Recommended = an toàn"~~ → Recommended là cho phone/TV
- ~~"Select all Recommended"~~ → Nguy hiểm với car unit

### Quy trình đúng

**Bước A: Export danh sách để phân tích**
```bash
# Export toàn bộ package ra file để nghiên cứu offline
adb shell pm list packages | sort > ~/Desktop/zestech_all_packages.txt

# Xem app đang chạy (hao tài nguyên)
adb shell pm list packages -e | sort > ~/Desktop/zestech_enabled.txt
```

**Bước B: Dùng UAD-ng để TRA CỨU — không phải auto-remove**

Trong UAD-ng:
1. Dùng **Search bar** để tìm package name từ file txt
2. Đọc **mô tả** (description) để biết package làm gì
3. Quyết định có remove không — rồi **làm bằng ADB thủ công** nếu không chắc

**Bước C: Remove từng nhóm nhỏ, test sau mỗi nhóm**

Thứ tự ưu tiên remove cho Zestech:

```bash
# Nhóm 1: Google Tracking/Ads (an toàn)
adb shell pm uninstall -k --user 0 com.google.android.feedback
adb shell pm uninstall -k --user 0 com.google.android.partnersetup

# Nhóm 2: App OEM không dùng (kiểm tra trước)
# Search trong UAD-ng, đọc mô tả, rồi quyết định

# Nhóm 3: App third-party pre-installed (thường an toàn)
# Ví dụ: WPS Office, TikTok, Facebook nếu có
```

---

## Cách dùng UAD-ng Search để tra cứu package Zestech

### Search theo loại

```
"analytics"    → tìm app tracking
"ads"          → tìm app quảng cáo  
"backup"       → tìm app backup (thường có thể disable)
"update"       → tìm app tự cập nhật
"store"        → tìm app store không cần thiết
```

### Package Zestech CẦN TRA CỨU TRƯỚC khi xóa

| Từ khóa nguy hiểm | Lý do |
|---|---|
| `launcher`, `home` | Launcher → mất giao diện xe |
| `mcu`, `can`, `vehicle` | Giao tiếp phần cứng xe |
| `camera`, `reverse` | Camera lùi |
| `carlink`, `carplay` | Apple CarPlay / Android Auto |
| `steering`, `wheel` | Nút vô-lăng |
| `bluetooth`, `bt` | Kết nối Bluetooth car |
| `gps`, `navi`, `map` | Navigation (cẩn thận) |

---

## Restore trong UAD-ng — 1 click

Ưu điểm lớn nhất của UAD-ng so với ADB thủ công:

1. Mở UAD-ng
2. Tab **"Disabled"** hoặc filter packages đã uninstall
3. Chọn package cần restore
4. Nhấn **"Restore selection"** → xong

Hoặc qua ADB:
```bash
adb shell cmd package install-existing com.ten.package.bi.xoa
```

---

## Test bắt buộc sau mỗi lần debloat

Làm theo thứ tự này (đỗ xe an toàn):

- [ ] Camera lùi khi gài số R
- [ ] Cảm biến lùi (tiếng beep)
- [ ] Camera 360 (nếu có)
- [ ] Nút vô-lăng (âm lượng, chuyển bài, nghe/cúp)
- [ ] Bluetooth điện thoại
- [ ] GPS / Maps
- [ ] Màn hình khởi động khi bật xe

---

## So sánh: UAD-ng vs ADB thủ công cho Zestech

| | UAD-ng | ADB thủ công |
|---|---|---|
| Tra cứu package | ✅ Search + mô tả | ❌ Google thủ công |
| Auto debloat profile | ❌ Không có cho car | N/A |
| Restore | ✅ 1 click | ✅ 1 lệnh |
| An toàn | ⚠️ Phải cẩn thận | ⚠️ Phải cẩn thận |
| Kết nối WiFi ADB | ✅ Detect tự động | ✅ `adb connect` |

**Kết luận:** Dùng **UAD-ng làm từ điển tra cứu** + **ADB thủ công để thực thi** → an toàn nhất.

---

## Workflow kết hợp tối ưu

```
1. UAD-ng mở → connect Zestech qua WiFi ADB
2. Search package trong UAD-ng → đọc mô tả
3. Nếu "an toàn" → dùng UAD-ng remove
4. Nếu "không chắc" → Google thêm → dùng ADB disable (không uninstall)
5. Test tính năng xe
6. Nếu lỗi → UAD-ng restore 1 click
```

---

## Checklist

- [ ] UAD-ng download và chạy được
- [ ] `adb connect IP:5555` thành công  
- [ ] Zestech hiện trong UAD-ng
- [ ] Export package list ra file để phân tích
- [ ] KHÔNG dùng "Select all Recommended"
- [ ] Remove từng nhóm nhỏ, test sau mỗi nhóm
- [ ] Test đầy đủ tính năng xe sau khi done
- [ ] Biết cách restore trong UAD-ng
