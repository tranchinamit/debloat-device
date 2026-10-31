# Quy trình Tối ưu Google Pixel Theo Từng Bước (Windows PowerShell)

Thư mục này chứa **4 file PowerShell tách rời theo từng bước** để bạn kiểm tra thông số, phân tích và tối ưu điện thoại Google Pixel trên máy tính Windows một cách chủ động.

Đặc biệt, ở **cả 4 bước**, sau khi chạy xong script sẽ **đồng thời**:
1. **Copy toàn bộ báo cáo định dạng Markdown vào Clipboard** (bạn có thể bấm `Ctrl+V` dán trực tiếp).
2. **Xuất 1 file báo cáo `.md` ra ngoài màn hình Desktop** (bạn có thể gửi file `.md` đó để phân tích).

| Thứ tự | File Script | File `.md` xuất ra ngoài Desktop | Chức năng |
| :--- | :--- | :--- | :--- |
| **Bước 1** | `step1_scan_pixel.ps1` | `Pixel_<Model>_Step1_Scan.md` | **100% Chỉ đọc (Read-Only):** Tự tải ADB nếu máy tính chưa có, lưu Backup ra Desktop, quét chi tiết Phần cứng, Độ chai Pin (Cycle Count), RAM, Bộ nhớ, Modem, App đang cài. |
| **Bước 2** | `step2_debloat_custom.ps1` | `Pixel_<Model>_Step2_Debloat.md` | **Gỡ Bloatware theo quyết định:** Hỗ trợ xem trước (`-DryRun`), gỡ theo nhóm (`-Group All / Carrier / Telemetry / BloatApps`) hoặc gỡ thêm gói bất kỳ (`-ExtraPackages`). Khóa bảo vệ cứng các tính năng độc quyền của Pixel (`Now Playing`, `eSIM`, `AICore`). |
| **Bước 3** | `step3_optimize_pixel.ps1` | `Pixel_<Model>_Step3_Optimize.md` | **Tối ưu Modem Tensor, Độ mượt & Pin chờ:** Tắt giữ sóng 4G/5G ngầm khi bắt Wi-Fi (`mobile_data_always_on = 0`), tắt quét Wi-Fi/BLE 24/7, đặt Animation `0.5x`, mở khóa đa nhiệm RAM lớn, dọn cache & chạy `bg-dexopt-job`. |
| **Bước 4** | `step4_verify_and_restore.ps1` | `Pixel_<Model>_Step4_Verify.md` | **Kiểm tra sau tối ưu & Khôi phục:** So sánh lại RAM/Bộ nhớ/Modem sau khi làm xong, hoặc khôi phục lại 1 gói (`-RestorePackage`) / toàn bộ (`-RestoreAll`). |

---

## Cách chạy trên máy tính Windows

Mở **PowerShell** tại thư mục chứa 4 file này và chạy lần lượt:

### Bước 1: Quét thông số & Kiểm tra hiện trạng máy
```powershell
powershell -ExecutionPolicy Bypass -File .\step1_scan_pixel.ps1
```
👉 *Chạy xong, bạn có thể bấm **Ctrl+V** hoặc lấy file `Pixel_<Model>_Step1_Scan.md` ngoài Desktop để phân tích tình trạng Pin, RAM, Bộ nhớ và quyết định danh sách app cần dọn ở Bước 2.*

---

### Bước 2: Xem trước và Gỡ Bloatware sau khi chốt danh sách
```powershell
# 1. Xem trước những gói nào sẽ được gỡ trên máy (chưa gỡ thật):
powershell -ExecutionPolicy Bypass -File .\step2_debloat_custom.ps1 -DryRun

# 2. Thực thi gỡ các nhóm rác an toàn của Pixel:
powershell -ExecutionPolicy Bypass -File .\step2_debloat_custom.ps1

# 3. (Tuỳ chọn) Nếu muốn gỡ thêm các gói cụ thể sau khi phân tích ở Bước 1:
powershell -ExecutionPolicy Bypass -File .\step2_debloat_custom.ps1 -ExtraPackages "com.ten.goi.1,com.ten.goi.2"
```
👉 *Xuất ra `Pixel_<Model>_Step2_Debloat.md` ngoài Desktop + Copy vào Clipboard.*

---

### Bước 3: Tối ưu mát Modem Tensor, Pin chờ & Độ mượt
```powershell
powershell -ExecutionPolicy Bypass -File .\step3_optimize_pixel.ps1
```
👉 *Xuất bảng so sánh Trước/Sau ra `Pixel_<Model>_Step3_Optimize.md` ngoài Desktop + Copy vào Clipboard.*

---

### Bước 4: Kiểm tra lại thông số (hoặc Khôi phục nếu cần)
```powershell
# Kiểm tra lại RAM, Bộ nhớ và cài đặt sau khi tối ưu:
powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1

# Nếu muốn khôi phục lại 1 gói cụ thể:
powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1 -RestorePackage com.google.android.videos

# Nếu muốn khôi phục toàn bộ về nguyên bản ban đầu:
powershell -ExecutionPolicy Bypass -File .\step4_verify_and_restore.ps1 -RestoreAll
```
👉 *Xuất báo cáo tổng kết sau cùng ra `Pixel_<Model>_Step4_Verify.md` ngoài Desktop + Copy vào Clipboard.*
