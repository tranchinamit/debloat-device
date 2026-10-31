# Hướng dẫn dùng UAD-ng để debloat điện thoại Android (macOS)

> Repo: [github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation)  
> UAD-ng = GUI viết bằng Rust, cross-platform, không cần root, chạy trên macOS.  
> Áp dụng cho: **Xiaomi / Redmi / POCO (MIUI / HyperOS)**, **Samsung Galaxy (One UI)** và bất kỳ điện thoại Android nào.

---

## Tại sao UAD-ng tốt hơn gõ ADB thủ công?

| Tính năng | ADB thủ công | UAD-ng |
|---|---|---|
| Giao diện | Terminal | GUI đồ họa |
| Màu sắc an toàn | ❌ Phải tự biết | ✅ 🟢🟡🔴 tự động |
| Tìm kiếm package | ❌ `grep` thủ công | ✅ Search bar |
| Mô tả từng app | ❌ Không có | ✅ Có sẵn (crowdsourced) |
| Restore | Lệnh dài | ✅ 1 click |
| Backup trước khi xóa | ❌ Tự làm | ✅ Tự động |
| Không cần nhớ lệnh Terminal | ❌ Phải gõ từng lệnh | ✅ Thao tác bằng chuột |
| Yêu cầu ADB (Platform-Tools) | ✅ Cần `adb` | ✅ Cần `adb` (chỉ cần Platform-Tools nhẹ ~10MB) |

---

## Bước 0 — Chuẩn bị công cụ trên máy tính

### 1. Cài ADB (Android Platform-Tools)
> ⚠️ **Lưu ý:** Không cần cài cả bộ Android SDK nặng vài GB (Android Studio). Bạn chỉ cần cài gói **Platform-Tools** siêu nhẹ (~10MB) chứa lệnh `adb`.

**Trên macOS (qua Homebrew):**
```bash
brew install android-platform-tools
```
*(Hoặc tải thủ công bản ZIP từ [Google Platform Tools](https://developer.android.com/tools/releases/platform-tools) rồi thêm vào PATH).*

**Kiểm tra xem máy đã có ADB chưa:**
```bash
adb version
```

### 2. Tải và cài UAD-ng
UAD-ng là ứng dụng giao diện (GUI) viết bằng Rust, dùng `adb` ở trên để thao tác với điện thoại.

1. Vào [Releases page](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/latest)
2. Download file phù hợp:
   - **Apple Silicon (M1/M2/M3):** `uad_ng-macos-apple-silicon.tar.gz`
   - **Intel Mac:** `uad_ng-macos-x86_64.tar.gz`
3. Giải nén và chạy:

```bash
# Giải nén
cd ~/Downloads
tar -xzf uad_ng-macos-*.tar.gz

# Cấp quyền thực thi và chạy (lần đầu macOS có thể chặn)
chmod +x uad_ng
./uad_ng
```

> Nếu macOS báo "cannot be opened because the developer cannot be verified":  
> **System Settings → Privacy & Security → Allow Anyway** (hoặc chuột phải vào app chọn **Open**).

---

## Bước 1 — Bật Developer Options trên điện thoại

### Xiaomi / Redmi / POCO (MIUI / HyperOS)
1. **Cài đặt → Giới thiệu điện thoại** (hoặc *Thông tin thiết bị*).
2. Bấm liên tục 7 lần vào **"Phiên bản OS"** (HyperOS) hoặc **"Phiên bản MIUI"** cho đến khi báo bạn đã là nhà phát triển.
3. Quay lại **Cài đặt → Cài đặt bổ sung (Cài đặt thêm) → Tùy chọn cho nhà phát triển**.
4. Bật **Gỡ lỗi USB (USB Debugging)** — *Đủ để UAD-ng kết nối và debloat xóa app*.
5. ⚠️ **Lưu ý đặc biệt cho Xiaomi (nếu muốn can thiệp sâu qua ADB):**  
   Để chạy được các lệnh `settings put` hoặc phân quyền nâng cao, Xiaomi bắt buộc phải bật thêm:  
   - **Gỡ lỗi USB (Cài đặt bảo mật)** / *USB debugging (Security settings)*.  
   - *Yêu cầu:* Phải lắp SIM có mạng di động + đăng nhập tài khoản Mi (Mi Account), sau đó xác nhận qua 3 bước cảnh báo 10 giây.  
   - *Nếu không bật:* Khi chạy lệnh `adb shell settings put ...` sẽ bị chặn với lỗi `java.lang.SecurityException: Permission denial, must have one of: [android.permission.WRITE_SECURE_SETTINGS]`.

### Samsung Galaxy (One UI)
1. **Cài đặt → Thông tin điện thoại → Thông tin phần mềm**.
2. Bấm liên tục 7 lần vào **"Số bản dựng"** (Build number).
3. Quay lại **Cài đặt → Cài đặt cho người phát triển** (hoặc *Tùy chọn nhà phát triển*).
4. Bật **Gỡ lỗi USB** (USB Debugging).  
> *Khác với Xiaomi, Samsung không chặn quyền shell đối với `settings put`, nên sau khi bật USB Debugging là bạn có thể thực thi đầy đủ các lệnh tối ưu qua ADB ngay mà không cần tài khoản hay SIM.*

---

## Bước 2 — Kết nối điện thoại với Mac

### Qua USB (đơn giản nhất)

```bash
# Kiểm tra máy tính đã nhận diện được thiết bị qua ADB:
adb devices
```

Cắm cáp USB → điện thoại hỏi "Allow USB debugging?" → bấm **Allow** → tích **Always allow from this computer**.

### Qua WiFi (không cần cáp) — Android 11+

**Samsung One UI 3+ (M55, M54...):**
1. **Developer Options → Wireless Debugging → Bật**
2. **Pair device with pairing code** → ghi mã 6 số và port

```bash
adb pair 192.168.1.XXX:PORT_PAIRING
# nhập mã 6 số
adb connect 192.168.1.XXX:5555
```

**Redmi Note 4 (MIUI / Android 7 — không có Wireless Debugging):**
```bash
# Cắm USB lần đầu, rồi:
adb tcpip 5555
# Rút USB, kết nối WiFi:
adb connect 192.168.1.XXX:5555
```

---

## Bước 3 — Mở UAD-ng và connect

1. Mở ứng dụng `uad_ng`
2. UAD-ng tự detect điện thoại đã connect qua ADB
3. Màn hình hiện danh sách app với màu sắc:

| Màu | Ý nghĩa |
|---|---|
| 🟢 **Recommended** | An toàn để remove — nên làm |
| 🟡 **Advanced** | Remove được nhưng cần hiểu tác động |
| 🔴 **Expert** | Nguy hiểm — không đụng vào |
| ⬛ **Unsafe** | Có thể brick máy |

---

## Bước 4 — Debloat với UAD-ng (GUI)

### Workflow chuẩn

1. **Chọn brand filter** (Xiaomi / Samsung / Google...) ở sidebar
2. **Search** để tìm app cụ thể
3. **Đọc mô tả** của từng package trước khi chọn
4. **Tick checkbox** các package muốn remove
5. **Nhấn "Debloat selection"**
6. UAD-ng tự backup và apply `pm uninstall -k --user 0`

### Tips sử dụng

```
Filter by: Recommended    ← chỉ xem app an toàn để xóa
Search: "analytics"       ← tìm app tracking
Search: "bixby"           ← Samsung specific
Search: "miui"            ← Xiaomi specific
```

### Nên xóa theo thứ tự ưu tiên

**Cho Redmi Note 4:**
1. Filter → Xiaomi → chọn tất cả 🟢 Recommended
2. Filter → Google → chọn những app không dùng
3. Search "analytics" → chọn tất cả

**Cho Samsung M55 / M cao cấp:**
1. Filter → Samsung → chọn tất cả 🟢 Recommended  
2. Search "bixby" → chọn tất cả
3. Search "facebook" → chọn tất cả
4. Filter → Microsoft → chọn những app không dùng

---

## Bước 5 — Restore nếu cần

### Qua UAD-ng GUI
1. Mở UAD-ng
2. **Tab "Restore"** hoặc filter **"Disabled"**
3. Chọn package muốn restore → **"Restore selection"**

### Qua ADB (nhanh hơn)
```bash
# Restore 1 package
adb shell cmd package install-existing com.samsung.android.bixby.agent

# Xem tất cả package đang disabled
adb shell pm list packages -d
```

---

## So sánh UAD-ng vs ADB thủ công cho từng thiết bị

| Thiết bị | UAD-ng | ADB thủ công |
|---|---|---|
| Redmi Note 4 | ✅ Có Xiaomi profile | ✅ Script trong guide cũ |
| Samsung M55 | ✅ Tốt nhất cho Samsung | ✅ Script trong guide cũ |
| Samsung M cao cấp | ✅ Tốt nhất cho Samsung | ✅ Script trong guide cũ |
| Zestech xe hơi | ⚠️ Không có car profile | ✅ Dùng ADB thủ công |

> ⚠️ **Zestech xe hơi**: UAD-ng không có profile cho Android car unit → dùng ADB thủ công theo [guide-debloat-zestech-xe-hoi.md](guide-debloat-zestech-xe-hoi.md) thay thế.

---

## Tối ưu thêm sau khi debloat (Samsung & Xiaomi)

### 1. Giảm tỷ lệ Animation (giúp giao diện phản hồi nhanh và mượt hơn)

3 thông số animation giúp rút ngắn một nửa thời gian chuyển động đồ họa (từ 1.0x xuống 0.5x), mang lại cảm giác máy nhanh và nhạy hơn rõ rệt:
- `window_animation_scale`: Tỷ lệ hình động cửa sổ (mở/đóng app, popup dialog).
- `transition_animation_scale`: Tỷ lệ hình động chuyển tiếp giữa các màn hình / Activity.
- `animator_duration_scale`: Thời lượng hiệu ứng chuyển động (progress bar, hiệu ứng bung menu).

#### Cách A: Chạy qua lệnh ADB
> Phù hợp với **Samsung** hoặc **Xiaomi đã bật "USB debugging (Security settings)"**:

```bash
# Giảm animation xuống 0.5x
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
```

> ⚠️ **Lỗi thường gặp trên Xiaomi:**  
> Nếu gặp `SecurityException: Permission denial (WRITE_SECURE_SETTINGS)`, nghĩa là máy Xiaomi chưa bật *Gỡ lỗi USB (Cài đặt bảo mật)*. Bạn có thể bật tính năng đó hoặc dùng **Cách B** trực tiếp trên màn hình máy.

#### Cách B: Chỉnh bằng tay trong Cài đặt (Không cần ADB, không lo lỗi quyền)
Vào **Cài đặt** → **Tùy chọn nhà phát triển** → cuộn đến nhóm **Hình vẽ** (Drawing) và chỉnh 3 mục về **0.5x**:
- *Tỷ lệ hình động của cửa sổ* → `0.5x`
- *Tỷ lệ hình động chuyển tiếp* → `0.5x`
- *Tỷ lệ thời lượng hình động* → `0.5x`

---

### 2. Giới hạn tiến trình chạy ngầm (Background Process Limit)

Giúp máy có dung lượng RAM khiêm tốn (3GB - 6GB) không bị quá tải do quá nhiều ứng dụng chạy nền cùng lúc.

#### Dùng lệnh ADB chuẩn (Android 11 - 15):
> ⚠️ **Lưu ý quan trọng:** Lệnh cũ `settings put global max_cached_processes 4` **không còn hiệu lực trên Android 11+ / Android 14, 15** và bị chặn trên Xiaomi. Hãy dùng lệnh `device_config` chuẩn sau (chạy được trên cả Samsung và Xiaomi mà không bị báo lỗi quyền):

```bash
# Giới hạn tối đa 4 tiến trình ngầm
adb shell device_config put activity_manager max_cached_processes 4

# Kiểm tra lại (tìm dòng CUR_MAX_CACHED_PROCESSES=4)
adb shell dumpsys activity settings | grep -i max_cached

# (Tùy chọn) Xóa giới hạn, đưa về mặc định của hệ điều hành:
adb shell device_config delete activity_manager max_cached_processes
```

#### Hoặc chỉnh trực tiếp trên điện thoại:
Vào **Tùy chọn nhà phát triển** → cuộn đến nhóm **Ứng dụng** (Apps) → **Giới hạn quá trình nền** (Background process limit) → chọn **Tối đa 4 quá trình** (*At most 4 processes*).

---

## Checklist

- [ ] Developer Options bật
- [ ] USB Debugging bật
- [ ] UAD-ng download và chạy được
- [ ] Điện thoại được detect trong UAD-ng
- [ ] Đã đọc mô tả từng package trước khi xóa
- [ ] Chỉ xóa 🟢 Recommended ở lần đầu
- [ ] Test sau debloat: gọi, SMS, camera, WiFi
- [ ] Biết cách restore trong UAD-ng

---

## Links hữu ích

| Link | Mô tả |
|---|---|
| [Releases](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/latest) | Download UAD-ng |
| [Wiki / Getting Started](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/wiki/Getting-started) | Hướng dẫn chính thức |
| [Usage Guide](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/wiki/Usage) | Chi tiết cách dùng |
| [Package database](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/tree/main/resources/packages) | Toàn bộ package list |
