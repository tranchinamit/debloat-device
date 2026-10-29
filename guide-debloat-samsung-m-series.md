# Hướng dẫn debloat Samsung Galaxy M series (M55 & dòng M cao cấp) trên macOS

> Áp dụng cho: **Galaxy M55 5G**, **M54 5G**, **M62**, **M52 5G** và các máy Samsung One UI tương đương.  
> Phương pháp: ADB `pm uninstall -k --user 0` — an toàn, restore được, không cần root.  
> Tool GUI tốt nhất: **Universal Android Debloater (UAD-ng)**.

---

## So sánh M55 vs dòng M cao cấp hơn

| | Galaxy M55 5G | M54 5G / M62 / M52 5G |
|---|---|---|
| Chip | Snapdragon 7 Gen 1 | Exynos 1380 / Dimensity 900 |
| One UI | 6.x (Android 14) | 5.x–6.x |
| RAM | 8GB | 6–8GB |
| Bloatware đặc trưng | Giống nhau (One UI) | Thêm Samsung DeX (M62) |
| Phương pháp debloat | **Giống hệt nhau** | **Giống hệt nhau** |

> ✅ Package list trong guide này dùng được cho **cả hai dòng**.

---

## Bước 0 — Cài công cụ trên Mac

```bash
# ADB
brew install android-platform-tools

# Kiểm tra
adb version
```

---

## Bước 1 — Bật Developer Options trên Samsung

1. **Cài đặt → Thông tin điện thoại (About phone) → Thông tin phần mềm (Software information)**
2. Bấm **"Số bản dựng / Build number"** 7 lần → "Developer mode has been turned on"
3. Quay lại **Cài đặt → Tùy chọn nhà phát triển (Developer Options)**
4. Bật **USB Debugging**

---

## Bước 2 — Kết nối ADB

### Cách A — Qua USB

```bash
# Cắm cáp USB vào Mac, chọn "File Transfer" trên điện thoại
adb devices
# Bấm "Allow" khi điện thoại hỏi
# → Thấy: XXXXXXXXXXXXXXXX   device
```

### Cách B — Qua WiFi (Android 11+, One UI 3+)

Samsung hỗ trợ **Wireless Debugging** với pairing code:

1. **Developer Options → Wireless debugging → Bật**
2. Chọn **"Pair device with pairing code"** → ghi lại IP, Port, và mã 6 số

```bash
# Pair lần đầu
adb pair 192.168.1.XXX:PORT_PAIRING
# Nhập mã 6 số hiện trên màn hình

# Connect
adb connect 192.168.1.XXX:5555

# Kiểm tra
adb devices
```

---

## Bước 3 — Xem package hiện tại

```bash
# Export toàn bộ package
adb shell pm list packages | sort > ~/Desktop/samsung_packages.txt

# Phân loại: hệ thống vs user-installed
adb shell pm list packages -s | sort > ~/Desktop/samsung_system_packages.txt
adb shell pm list packages -3 | sort > ~/Desktop/samsung_user_packages.txt

# Xem package đã bị disabled
adb shell pm list packages -d
```

---

## Bước 4 — Debloat

### Cú pháp

```bash
# Xóa cho user 0 (AN TOÀN — restore được)
adb shell pm uninstall -k --user 0 <package_name>

# Hoặc disable (giữ nguyên nhưng không chạy)
adb shell pm disable-user --user 0 <package_name>
```

---

### Nhóm 1: Bixby — AN TOÀN nếu không dùng

```bash
adb shell pm uninstall -k --user 0 com.samsung.android.bixby.agent
adb shell pm uninstall -k --user 0 com.samsung.android.bixby.wakeup
adb shell pm uninstall -k --user 0 com.samsung.android.bixby.service
adb shell pm uninstall -k --user 0 com.samsung.android.bixbyvision.framework
adb shell pm uninstall -k --user 0 com.samsung.android.app.settings.bixby
adb shell pm uninstall -k --user 0 com.samsung.android.bixby.agent.dummy
```

### Nhóm 2: Facebook/Meta — AN TOÀN (nên xóa)

```bash
adb shell pm uninstall -k --user 0 com.facebook.katana
adb shell pm uninstall -k --user 0 com.facebook.system
adb shell pm uninstall -k --user 0 com.facebook.appmanager
adb shell pm uninstall -k --user 0 com.facebook.services
```

### Nhóm 3: Samsung Marketing & Bloat Apps

```bash
adb shell pm uninstall -k --user 0 com.samsung.android.app.spage       # Samsung Free / Daily
adb shell pm uninstall -k --user 0 com.samsung.android.forest          # Digital Wellbeing widget
adb shell pm uninstall -k --user 0 com.samsung.android.app.tips        # Tips app
adb shell pm uninstall -k --user 0 com.sec.android.daemonapp           # Weather daemon
adb shell pm uninstall -k --user 0 com.samsung.android.themestore      # Theme Store (nếu không dùng)
adb shell pm uninstall -k --user 0 com.samsung.android.app.watchmanager  # Galaxy Watch Manager (nếu không có Watch)
```

### Nhóm 4: AR & Camera extras

```bash
adb shell pm uninstall -k --user 0 com.samsung.android.arzone          # AR Zone
adb shell pm uninstall -k --user 0 com.samsung.android.livestickers    # Live Stickers
# Giữ lại nếu dùng AR apps/games:
# adb shell pm uninstall -k --user 0 com.google.ar.core
```

### Nhóm 5: Game Services (tuỳ chọn)

> ⚠️ Cẩn thận với `game.gos` nếu bạn hay chơi game nặng

```bash
adb shell pm uninstall -k --user 0 com.samsung.android.game.gamehome   # Game Launcher
adb shell pm uninstall -k --user 0 com.samsung.android.game.gametools  # Game Tools
# adb shell pm uninstall -k --user 0 com.samsung.android.game.gos     # GOS - chỉ xóa nếu không chơi game
```

### Nhóm 6: Microsoft & Partner Apps

```bash
adb shell pm uninstall -k --user 0 com.microsoft.office.officehubrow   # Microsoft 365
adb shell pm uninstall -k --user 0 com.microsoft.appmanager            # Link to Windows
adb shell pm uninstall -k --user 0 com.linkedin.android               # LinkedIn (nếu có)
adb shell pm uninstall -k --user 0 com.netflix.partner.activation      # Netflix stub (nếu có)
```

### Nhóm 7: Samsung Knox & Enterprise (chỉ xóa nếu máy cá nhân, không quản lý bởi MDM)

```bash
# Chỉ khi máy hoàn toàn cá nhân:
# adb shell pm uninstall -k --user 0 com.samsung.android.knox.containeragent
# adb shell pm uninstall -k --user 0 com.samsung.android.mdm.policy.fota
```

### Nhóm 8: Miscellaneous

```bash
adb shell pm uninstall -k --user 0 com.android.printspooler            # Print Spooler (nếu không in)
adb shell pm uninstall -k --user 0 com.sec.print.spprintservice        # Samsung Print
adb shell pm uninstall -k --user 0 com.android.bookmarkprovider        # Browser bookmarks provider
# adb shell pm uninstall -k --user 0 com.samsung.android.app.routines  # Modes & Routines (GIỮ nếu dùng)
```

---

## Tối ưu animation (mượt hơn)

```bash
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
```

---

## Restore — Khôi phục app

```bash
# Restore 1 app cụ thể
adb shell cmd package install-existing com.samsung.android.bixby.agent

# Xem danh sách app đang bị uninstalled/disabled
adb shell pm list packages -d
adb shell pm list packages -u   # uninstalled packages
```

---

## Tool GUI — Universal Android Debloater (UAD-ng)

> **Khuyến nghị mạnh** cho Samsung — có sẵn package list Samsung cụ thể, đánh dấu màu an toàn/nguy hiểm.

```bash
# Download từ:
# https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases
# Chọn file: uad_ng-macos-apple-silicon.tar.gz (M1/M2) hoặc uad_ng-macos-x86_64.tar.gz (Intel)

# Giải nén và chạy:
./uad_ng
```

**Giao diện UAD-ng:**
- 🟢 **Recommended** = An toàn để xóa
- 🟡 **Advanced** = Cần biết mình đang làm gì
- 🔴 **Expert** = Nguy hiểm, không nên đụng
- ⬛ **Unsafe** = Có thể brick máy

---

## KHÔNG được xóa (brick máy)

| Package | Lý do |
|---|---|
| `com.android.systemui` | System UI |
| `com.android.settings` | Cài đặt |
| `com.samsung.android.settings` | Samsung Settings |
| `android` | Core Android |
| `com.android.phone` | Ứng dụng gọi điện |
| `com.android.providers.telephony` | SMS/Call provider |
| `com.sec.android.app.launcher` | Samsung launcher (giữ nếu chưa cài launcher khác) |
| `com.samsung.android.devicecare` | Device Care — gắn với battery/storage |
| `com.android.contacts` | Danh bạ |

---

## Package đặc trưng dòng M cao cấp hơn (M54/M62)

```bash
# Galaxy M62 có Samsung DeX — chỉ xóa nếu không dùng
# adb shell pm uninstall -k --user 0 com.samsung.android.dex.pip

# M54 có thể có Samsung Pay mini
# Kiểm tra trước: adb shell pm list packages | grep "samsung.pay"
```

---

## Script all-in-one (chạy 1 lần)

Tạo file `samsung-debloat.sh`:

```bash
#!/bin/bash
# Samsung Galaxy M series Debloat Script
# Chạy: chmod +x samsung-debloat.sh && ./samsung-debloat.sh

PKG_LIST=(
  # Bixby
  "com.samsung.android.bixby.agent"
  "com.samsung.android.bixby.wakeup"
  "com.samsung.android.bixby.service"
  "com.samsung.android.bixbyvision.framework"
  "com.samsung.android.app.settings.bixby"
  # Facebook
  "com.facebook.system"
  "com.facebook.appmanager"
  "com.facebook.services"
  # Samsung Bloat
  "com.samsung.android.app.spage"
  "com.samsung.android.app.tips"
  "com.sec.android.daemonapp"
  "com.samsung.android.arzone"
  "com.samsung.android.livestickers"
  # Microsoft
  "com.microsoft.office.officehubrow"
  "com.microsoft.appmanager"
  # Game (bỏ comment nếu không chơi game)
  # "com.samsung.android.game.gamehome"
  # "com.samsung.android.game.gametools"
)

for pkg in "${PKG_LIST[@]}"; do
  echo -n "Disabling $pkg... "
  adb shell pm uninstall -k --user 0 "$pkg" 2>/dev/null && echo "✓" || echo "skip (not found)"
done

echo ""
echo "✅ Done! Optimizing animations..."
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
echo "✅ All done!"
```

```bash
# Chạy script
chmod +x samsung-debloat.sh
./samsung-debloat.sh
```

---

## Checklist

- [ ] Developer Options bật
- [ ] USB Debugging bật
- [ ] `adb devices` thấy máy (hoặc WiFi connect thành công)
- [ ] Export package list ra file trước
- [ ] Debloat theo nhóm, kiểm tra từng nhóm
- [ ] Animation đã tối ưu
- [ ] Test: gọi điện, SMS, camera, Face ID, Samsung Pay (nếu dùng)
- [ ] Biết lệnh restore khi cần
