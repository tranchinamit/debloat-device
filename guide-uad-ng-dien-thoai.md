# Hướng dẫn dùng UAD-ng để debloat điện thoại Android (macOS)

> Repo: [github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation)  
> UAD-ng = GUI viết bằng Rust, cross-platform, không cần root, chạy trên macOS.  
> Áp dụng cho: **Redmi Note 4**, **Samsung Galaxy M55**, **Samsung M cao cấp** và bất kỳ Android nào.

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
| Không cần ADB cài sẵn | ❌ Bắt buộc | ✅ Bundled |

---

## Bước 0 — Cài UAD-ng trên Mac

### Download binary (không cần build)

1. Vào [Releases page](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/latest)
2. Download file phù hợp:
   - **Apple Silicon (M1/M2/M3):** `uad_ng-macos-apple-silicon.tar.gz`
   - **Intel Mac:** `uad_ng-macos-x86_64.tar.gz`
3. Giải nén và chạy:

```bash
# Giải nén
cd ~/Downloads
tar -xzf uad_ng-macos-*.tar.gz

# Chạy (lần đầu macOS có thể chặn)
./uad_ng
```

> Nếu macOS báo "cannot be opened because the developer cannot be verified":  
> **System Settings → Privacy & Security → Allow Anyway**

### Hoặc cài qua Homebrew (nếu có trong cask)

```bash
# Kiểm tra
brew search uad
# Nếu có thì:
brew install --cask uad-ng
```

---

## Bước 1 — Bật Developer Options trên điện thoại

### Redmi Note 4 (MIUI)
1. **Cài đặt → Giới thiệu điện thoại**
2. Bấm **"Phiên bản MIUI"** 7 lần
3. **Cài đặt → Cài đặt thêm → Tùy chọn nhà phát triển**
4. Bật **USB Debugging**

### Samsung Galaxy M55 / M cao cấp (One UI)
1. **Cài đặt → Thông tin điện thoại → Thông tin phần mềm**
2. Bấm **"Số bản dựng"** 7 lần
3. **Cài đặt → Tùy chọn nhà phát triển**
4. Bật **USB Debugging**

---

## Bước 2 — Kết nối điện thoại với Mac

### Qua USB (đơn giản nhất)

```bash
# Kiểm tra ADB thấy máy (UAD-ng dùng ADB riêng của nó)
# Nhưng bạn có thể dùng lệnh này để verify trước:
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

## Tối ưu thêm sau khi debloat (bất kỳ điện thoại nào)

```bash
# Giảm animation → mượt hơn rõ rệt
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5

# Giới hạn background processes
adb shell settings put global max_cached_processes 4
```

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
