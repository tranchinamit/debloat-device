# Hướng dẫn debloat Xiaomi Redmi Note 4 (MIUI) trên macOS

> Redmi Note 4 chạy MIUI (Android 6/7) — dùng ADB qua USB hoặc WiFi.  
> Phương pháp: `pm uninstall -k --user 0` — app bị ẩn cho user, KHÔNG bị xóa khỏi firmware.  
> Restore bất cứ lúc nào bằng 1 lệnh.

---

## So sánh nhanh với TV / màn hình xe

| | Cooca TV | Zestech xe | Redmi Note 4 |
|---|---|---|---|
| Kết nối | WiFi (ADB 5555) | WiFi (ADB 5555) | USB **hoặc** WiFi |
| Rủi ro | Thấp | Trung bình | Thấp (user 0 uninstall) |
| Restore | `restore.sh` | `restore.sh` | `cmd package install-existing` |
| CleanYourTV | ✅ Toàn bộ | ⚠️ Chỉ 1 phần | ❌ Không áp dụng |
| Tool tốt nhất | CleanYourTV | ADB manual | UAD-ng hoặc ADB manual |

---

## Bước 0 — Cài công cụ trên Mac

```bash
# Cài ADB
brew install android-platform-tools

# Kiểm tra
adb version
```

---

## Bước 1 — Bật Developer Options trên Redmi Note 4

1. **Cài đặt → Giới thiệu điện thoại (About phone)**
2. Bấm **"Phiên bản MIUI / MIUI Version"** 7 lần → "Bạn là nhà phát triển!"
3. Quay lại **Cài đặt → Cài đặt thêm (Additional Settings) → Tùy chọn nhà phát triển**
4. Bật **USB Debugging**

---

## Bước 2 — Kết nối ADB

### Cách A — Qua USB (đơn giản nhất)

```bash
# Cắm cáp USB vào Mac
adb devices
# → Điện thoại hỏi "Allow USB debugging?" → bấm Allow
# → Thấy: XXXXXXXX   device
```

### Cách B — Qua WiFi (không cần cáp)

```bash
# Bước 1: Cắm USB lần đầu để kích hoạt
adb devices   # đảm bảo kết nối

# Bước 2: Bật ADB TCP
adb tcpip 5555

# Bước 3: Tìm IP điện thoại
# Cài đặt → Giới thiệu → Địa chỉ IP
# Hoặc: Cài đặt → WiFi → [Tên mạng] → IP

# Bước 4: Rút USB, connect WiFi
adb connect 192.168.1.XXX:5555
adb devices   # phải thấy: 192.168.1.XXX:5555   device
```

---

## Bước 3 — Xem package hiện tại

```bash
# Export toàn bộ package
adb shell pm list packages | sort > ~/Desktop/redmi_note4_packages.txt

# Xem app đang chạy nền (hao battery)
adb shell ps

# Xem RAM usage
adb shell dumpsys meminfo | head -40
```

---

## Bước 4 — Debloat

> **Lưu ý:** Redmi Note 4 có nhiều biến thể (Mido - Global, India). Kiểm tra package nào tồn tại trước khi chạy.

### Kiểm tra package có tồn tại không

```bash
adb shell pm list packages | grep "com.miui.analytics"
# Nếu có kết quả → package tồn tại → có thể disable
```

### Script debloat nhanh (copy và chạy từng nhóm)

#### Nhóm 1: Ads, Analytics, Tracking (AN TOÀN — nên xóa)
```bash
adb shell pm uninstall -k --user 0 com.miui.analytics
adb shell pm uninstall -k --user 0 com.miui.msa.global
adb shell pm uninstall -k --user 0 com.miui.systemAdSolution
adb shell pm uninstall -k --user 0 com.miui.bugreport
adb shell pm uninstall -k --user 0 com.miui.daemon
adb shell pm uninstall -k --user 0 com.miui.hybrid
adb shell pm uninstall -k --user 0 com.miui.hybrid.accessory
```

#### Nhóm 2: GetApps & Xiaomi Services (AN TOÀN)
```bash
adb shell pm uninstall -k --user 0 com.xiaomi.mipicks          # GetApps store
adb shell pm uninstall -k --user 0 com.xiaomi.gamecenter.sdk   # Game Center
adb shell pm uninstall -k --user 0 com.miui.cloudservice       # Mi Cloud (nếu không dùng)
adb shell pm uninstall -k --user 0 com.miui.backup             # Mi Backup (nếu không dùng)
```

#### Nhóm 3: App Mi thay thế được bằng Google apps
```bash
adb shell pm uninstall -k --user 0 com.mi.globalbrowser        # Mi Browser
adb shell pm uninstall -k --user 0 com.miui.videoplayer        # Mi Video
adb shell pm uninstall -k --user 0 com.miui.player             # Mi Music
adb shell pm uninstall -k --user 0 com.miui.android.fashiongallery  # Glance / Wallpaper Carousel
adb shell pm uninstall -k --user 0 com.miui.weather2           # Mi Weather
# adb shell pm uninstall -k --user 0 com.miui.notes            # Bỏ comment nếu không dùng
# adb shell pm uninstall -k --user 0 com.miui.calculator       # Bỏ comment nếu không dùng
```

#### Nhóm 4: Facebook (AN TOÀN — nên xóa)
```bash
adb shell pm uninstall -k --user 0 com.facebook.appmanager
adb shell pm uninstall -k --user 0 com.facebook.services
adb shell pm uninstall -k --user 0 com.facebook.system
adb shell pm uninstall -k --user 0 com.facebook.katana         # Nếu có
```

#### Nhóm 5: Google bloatware (tuỳ chọn)
```bash
# Chỉ xóa nếu có app thay thế
# adb shell pm uninstall -k --user 0 com.google.android.music
# adb shell pm uninstall -k --user 0 com.google.android.videos
# adb shell pm uninstall -k --user 0 com.google.android.apps.photos   # Dùng nếu không dùng Google Photos
```

---

## Tối ưu thêm (không cần xóa app)

```bash
# Giảm animation → mượt hơn rõ rệt trên máy cũ
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5

# Tắt hoàn toàn (máy cảm giác nhanh hơn hẳn)
# adb shell settings put global window_animation_scale 0
# adb shell settings put global transition_animation_scale 0
# adb shell settings put global animator_duration_scale 0

# Giới hạn background process
adb shell settings put global max_cached_processes 4

# Force GPU rendering
adb shell setprop debug.egl.hw 1
```

---

## Restore — Khôi phục bất kỳ app nào

```bash
# Khôi phục 1 app cụ thể
adb shell cmd package install-existing com.miui.analytics

# Kiểm tra app đang bị disabled
adb shell pm list packages -d
```

---

## KHÔNG được xóa (có thể brick máy)

| Package | Lý do |
|---|---|
| `com.miui.home` | Launcher MIUI — mất là mất màn hình chính |
| `com.android.settings` | Cài đặt hệ thống |
| `com.miui.securitycenter` | Security & Battery center |
| `android` | Core Android |
| `com.android.systemui` | System UI |
| `com.android.phone` | Ứng dụng cuộc gọi |
| `com.android.providers.telephony` | SMS/Call provider |
| `com.android.contacts` | Danh bạ |

---

## Tool GUI thay thế (dễ hơn command line)

### Universal Android Debloater Next Generation (UAD-ng)
- Repo: [github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation)
- Có bản macOS, giao diện đồ họa
- Package được đánh dấu màu: 🟢 An toàn / 🟡 Thận trọng / 🔴 Nguy hiểm
- **Khuyến nghị nếu không quen dùng terminal**

```bash
# Cài UAD-ng qua Homebrew (nếu có)
brew install --cask uad-ng

# Hoặc download release từ GitHub
```

---

## Checklist

- [ ] Developer Options đã bật
- [ ] USB Debugging đã bật
- [ ] `adb devices` thấy máy
- [ ] Export package list ra file trước
- [ ] Kiểm tra từng package trước khi xóa
- [ ] Test sau debloat: gọi điện, SMS, camera, WiFi, GPS
- [ ] Biết lệnh restore khi cần
