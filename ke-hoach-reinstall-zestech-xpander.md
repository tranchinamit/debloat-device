# Kế hoạch reinstall màn hình Zestech cho Mitsubishi Xpander (chip cũ, RAM 2–4GB)

## Giai đoạn 0: Kiểm tra trước khi làm
1. **Xác định chính xác phần cứng.** Cài app *CPU-Z* hoặc *AIDA64*, rồi ghi lại:
   - Chip: PX5 (RK3368), PX6 (RK3399), RK3188, MTK8227, v.v.
   - RAM và ROM.
   - Phiên bản Android hiện tại.
   - Model main unit (Cài đặt → Thông tin hệ thống, hoặc tem sau lưng màn hình).
2. **Xác định MCU.** Vào *Cài đặt xe/Factory settings* (mật khẩu thường là `126`, `3368`, `8888` hoặc `7890`). Ghi lại phiên bản MCU, vì MCU sai sẽ làm mất nút vô-lăng, camera, CAN-bus.
3. **Sao lưu ROM gốc.** Xin file firmware gốc từ nhà bán/Zestech. Nếu không có, dùng công cụ backup của hãng chip (RKDevTool) để dump.
4. Chụp ảnh toàn bộ cài đặt hiện có: Factory settings, loại CAN-bus (Xpander thường dùng decoder CAN riêng), camera 360 và camera lùi, EQ/DSP.

## Giai đoạn 1: Chọn hướng nâng cấp
| Hướng | Độ mượt | Rủi ro | Khuyến nghị |
|---|---|---|---|
| **A. Factory reset + dọn app** | Trung bình | Thấp | Làm trước tiên. Nhiều khi đã đủ. |
| **B. ROM chính hãng mới (Android 10/12) từ Zestech** | Khá | Thấp | Nên làm nếu hãng có bản mới đúng model. |
| **C. ROM custom + launcher nhẹ** | Cao | Trung bình–cao | Chỉ làm khi ROM đúng chip, đúng MCU. |
| **D. Thêm Android box cắm USB/CarPlay** | Rất cao | Thấp | An toàn nhất nếu chip quá yếu. |

> **Quan trọng:** Với chip cũ và RAM 2–4GB, ROM mới hơn chưa chắc mượt hơn. Android 8–10 bản nhẹ thường mượt hơn Android 12. Giới hạn nằm ở phần cứng.

## Giai đoạn 2: Tối ưu trước khi flash (Hướng A)
1. Backup dữ liệu cần giữ: danh bạ, bản đồ offline, ảnh.
2. Factory reset toàn bộ.
3. Chỉ cài app cần thiết: Google Maps hoặc Vietmap, Spotify/Zing, YouTube Vanced/NewPipe.
4. Cài launcher nhẹ: *AGAMA Car Launcher*, *CarWebGuru* hoặc *Nova*. Tắt widget và live wallpaper.
5. Developer options:
   - Window/Transition/Animator scale = 0.5x hoặc tắt.
   - Giới hạn background process ở mức 2–3.
   - Tắt app tự khởi động bằng *Autostart Manager*.
6. Gỡ bloatware và app OEM không dùng (ADB `pm disable-user`).
7. Dùng thẻ nhớ/USB chất lượng tốt. Thẻ chậm cũng làm máy ì.

## Giai đoạn 3: Flash ROM (Hướng B/C)
### Chuẩn bị
- Laptop Windows, cáp USB-A to A (hoặc cổng USB debug trên máy).
- Driver *Rockchip DriverAssistant* hoặc *MTK VCOM*.
- Công cụ: *RKDevTool* / *AndroidTool* (Rockchip), *SP Flash Tool* (MTK).
- Nguồn điện ổn định: cấp 12V ngoài hoặc để xe nổ máy khi flash.
- ROM đúng chip và độ phân giải. Kiểm tra checksum MD5.

### Các bước
1. Tải ROM và công cụ, đối chiếu đúng model và chip.
2. Đưa máy vào chế độ loader/maskrom (thường giữ nút reset/boot khi cấp nguồn).
3. Flash theo hướng dẫn của ROM. Với Rockchip: *Upgrade Firmware* → *Update*.
4. Đợi hoàn tất, không rút nguồn.
5. Khởi động lần đầu (có thể mất vài phút), sau đó flash lại MCU nếu ROM yêu cầu.

## Giai đoạn 4: Cấu hình sau cài
1. Nhập lại **Factory settings** đã chụp ở bước 0: CAN-bus, vô-lăng, camera 360, DSP.
2. Chọn đúng giao thức CAN cho Xpander (thường Mitsubishi/Raise/Hiworld).
3. Test: camera lùi, nút vô-lăng, điều hòa, đèn, cảm biến lùi, micro, Bluetooth.
4. Root nếu cần (không bắt buộc).
5. Cài lại app tối giản theo Giai đoạn 2.

## Giai đoạn 5: Dự phòng
- **Brick:** vào chế độ Maskrom/Loader để flash lại ROM gốc đã backup.
- **Mất nút vô-lăng/camera:** flash lại MCU hoặc nhập lại Factory settings.
- **Vẫn chậm:** chuyển sang Hướng D, tức Android box hoặc thay main unit (Qualcomm 6–8 core, RAM 6–8GB).

## An toàn khi mất nút vô-lăng / camera
**Không ảnh hưởng đến an toàn lái xe:** phanh, lái, túi khí, ABS, cruise control/limiter và các tính năng ADAS (giữ làn, cảnh báo va chạm, nếu xe có) do ECU, camera và radar của xe điều khiển. Chúng độc lập với màn hình Zestech.

**Có thể bị ảnh hưởng nếu cấu hình sai:** nút âm lượng/chuyển bài/nghe gọi trên vô-lăng, thông số xe qua CAN, cảm biến lùi, camera lùi và camera 360.

Quy trình kiểm tra sau khi flash hoặc reset (làm khi đỗ xe, không thử khi đang lái):
1. Test **camera lùi trước tiên**. Khi chưa có hình, không lùi xe chỉ dựa vào màn hình, mà nhìn gương và nhờ người hướng dẫn.
2. Test cảm biến lùi và camera 360.
3. Test nút vô-lăng (âm lượng, chuyển bài, nghe/ngắt gọi) và gán lại phím nếu cần.
4. Test điều hòa, đèn và thông tin CAN.
5. Chỉ đưa xe ra đường sau khi các mục trên đều hoạt động.

Lưu ý khi tháo lắp:
- Tắt máy và ngắt khóa điện trước khi tháo giắc.
- Không tự cắm vào giắc OBD hoặc CAN-bus khi chưa biết giao thức.
- Chụp ảnh sơ đồ dây trước khi tháo để lắp lại đúng.
- Kiểm tra xe mình có tính năng giữ làn/FCM không. Xpander đời cũ thường không có.

## Lưu ý quan trọng
- Không flash ROM của hãng khác (Joying, Eonon...) vào Zestech nếu chưa chắc MCU/giao thức tương thích.
- Không cắt nguồn khi đang flash.
- Nếu không quen thao tác, nhờ kỹ thuật viên hãng.

## Thông tin cần thu thập (checklist)
- [ ] Tên model main unit (ví dụ Zestech DX-xxx)
- [ ] Chip, RAM, ROM, phiên bản Android (ảnh CPU-Z)
- [ ] Phiên bản MCU
- [ ] Ảnh Factory settings (CAN-bus, vô-lăng, camera)
- [ ] File firmware gốc đã backup
- [ ] Ảnh sơ đồ dây và giắc trước khi tháo
- [ ] Đã test camera lùi và nút vô-lăng sau khi cài lại
