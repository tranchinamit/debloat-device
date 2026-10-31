#!/usr/bin/env python3
import subprocess
import sys

# Danh sách ứng dụng rác, quảng cáo, theo dõi an toàn 100% để gỡ
# TUYỆT ĐỐI KHÔNG CHỨA:
# - Bất kỳ gói nào có tên 'overlay' (gây crash Zygote và Settings)
# - Driver phần cứng Qualcomm (IMS/VoLTE, WiFi, Location, RIL)
# - GMS Core (Google Play Services, Play Store, WebView, GSF)
# - Các app Google thiết yếu (Dialer, Contacts, Maps, Photos, Gmail)
# - Dịch vụ cảm ứng / bảo mật cốt lõi (TouchService, TrustService, SecurityCenter)

SAFE_DEBLOAT_PACKAGES = [
    # 1. Quảng cáo, theo dõi, thu thập dữ liệu ngầm của Xiaomi
    ("com.miui.msa.global", "Xiaomi System Ads (Quảng cáo hệ thống)"),
    ("com.miui.analytics", "Xiaomi Analytics (Thu thập & gửi dữ liệu ngầm)"),
    ("com.miui.daemon", "Xiaomi Daemon (Tiến trình thu thập nền)"),
    ("com.miui.bugreport", "Báo cáo lỗi Xiaomi ngầm"),
    ("com.miui.miservice", "Dịch vụ phản hồi Xiaomi"),
    ("com.miui.misightservice", "Dịch vụ theo dõi trải nghiệm MiSight"),
    ("com.mi.appfinder", "App Finder / Gợi ý app rác"),
    ("com.mi.globalminusscreen", "Màn hình -1 App Vault"),
    ("com.xiaomi.mipicks", "GetApps (Kho app Xiaomi spam thông báo)"),
    ("com.miui.yellowpage", "Trang vàng danh bạ Xiaomi"),
    ("com.xiaomi.payment", "Mi Pay (Dịch vụ thanh toán Xiaomi)"),
    ("com.xiaomi.glgm", "Xiaomi Game Center"),
    ("com.xiaomi.barrage", "Chữ chạy màn hình Xiaomi"),
    ("com.xiaomi.aiasst.vision", "AI Vision Xiaomi"),
    ("com.miui.thirdappassistant", "Trợ lý ứng dụng bên thứ 3"),
    ("com.miui.phrase", "Cụm từ mẫu bàn phím Xiaomi"),

    # 2. Ứng dụng media mặc định của Xiaomi (nhiều quảng cáo)
    ("com.mi.globalbrowser", "Mi Browser (Trình duyệt mặc định nhiều quảng cáo)"),
    ("com.miui.videoplayer", "Mi Video (Trình phát video nhiều quảng cáo)"),
    ("com.miui.player", "Mi Music (Trình nghe nhạc Xiaomi)"),

    # 3. Facebook bloatware chạy ngầm
    ("com.facebook.services", "Facebook Services"),
    ("com.facebook.system", "Facebook System"),
    ("com.facebook.appmanager", "Facebook App Manager"),

    # 4. Microsoft tích hợp
    ("com.microsoftsdk.crossdeviceservicebroker", "Microsoft Link to Windows Broker"),

    # 5. Các công cụ kiểm thử / cấu hình rác của nhà mạng & nhà máy
    ("com.fingerprints.sensortesttool", "Test cảm biến vân tay nhà máy"),
    ("com.goodix.gftest", "Test cảm biến Goodix"),
    ("com.longcheertel.AutoTest", "Auto Test nhà máy"),
    ("com.longcheertel.cit", "CIT Test nhà máy"),
    ("com.longcheertel.sarauth", "SAR Auth nhà máy"),
    ("com.wdstechnology.android.kryten", "Cấu hình OMA-DM nhà mạng"),
    ("com.qualcomm.qti.remoteSimlockAuth", "Simlock Auth không dùng"),
    ("com.qualcomm.qti.ridemodeaudio", "Ride Mode Audio Qualcomm"),
    ("com.qti.snapdragon.qdcm_ff", "QDCM Color Mode test"),

    # 6. Dịch vụ rác & app Google không cần thiết (không ảnh hưởng GMS Core)
    ("com.google.android.feedback", "Google Feedback (Gửi phản hồi lỗi ngầm)"),
    ("com.google.android.apps.subscriptions.red", "Google One promo"),
    ("com.google.android.apps.restore", "Google Setup Restore (Chỉ dùng khi unbox)"),
    ("com.google.android.apps.tachyon", "Google Duo / Meet"),
    ("com.google.android.videos", "Google TV"),
    ("com.android.traceur", "System Tracing dev log"),
    ("com.android.egg", "Android Easter Egg"),
    ("com.android.providers.partnerbookmarks", "Bookmarks đối tác mặc định"),

    # 7. Các tiến trình ngầm ăn RAM nặng trên máy 4GB RAM (Đợt 2)
    ("com.miui.guardprovider", "Bộ quét virus ngầm Avast/Tencent (ngốn ~120MB RAM)"),
    ("com.xiaomi.aicr", "Xiaomi AI Engine ngầm (nặng máy trên RAM 4GB)"),
    ("com.xiaomi.ugd", "Dịch vụ ngầm Xiaomi UGD"),
    ("com.xiaomi.discover", "Trình gợi ý cập nhật ứng dụng hệ thống Xiaomi"),
    ("com.bsp.logmanager", "CatchLog_Lc (Ghi log debug nhà máy Longcheer)"),
    ("com.novatek.novavis", "NovaJarvis (Công cụ debug màn hình Novatek)"),
    ("com.miui.virtualsim", "Mi Roaming (SIM ảo Xiaomi)"),
    ("com.miui.vsimcore", "Virtual SIM Core"),
    ("com.miui.cloudbackup", "Sao lưu đám mây Xiaomi Cloud"),
    ("com.miui.micloudsync", "Đồng bộ Xiaomi Cloud chạy ngầm"),
    ("com.google.android.as", "Android System Intelligence (ngốn ~103MB RAM ngầm)"),
    ("com.google.android.as.oss", "Private Compute Services (đi kèm System Intelligence)"),
    ("com.android.hotwordenrollment.okgoogle", "Lắng nghe mic OK Google 24/7 (ngốn ~103MB RAM)"),
    ("com.android.hotwordenrollment.xgoogle", "Lắng nghe mic Hey Google 24/7"),
    ("com.google.android.apps.wellbeing", "Digital Wellbeing (Theo dõi thời gian dùng app gây khựng)"),
    ("com.google.mainline.telemetry", "Google Mainline Telemetry"),
    ("com.google.mainline.adservices", "Google Mainline AdServices (Quảng cáo)"),
    ("com.google.android.adservices.api", "Google AdServices API"),
    ("com.google.android.ondevicepersonalization.services", "Cá nhân hóa quảng cáo trên thiết bị"),
    ("com.google.android.federatedcompute", "Huấn luyện dữ liệu quảng cáo ngầm"),
    ("com.google.android.marvin.talkback", "TalkBack (Đọc màn hình cho người khiếm thị)"),
    ("com.google.android.accessibility.switchaccess", "Switch Access"),
]

def main():
    installed = set(
        subprocess.check_output(["adb", "shell", "pm", "list", "packages"])
        .decode()
        .splitlines()
    )
    installed = {p.replace("package:", "").strip() for p in installed}

    print(f"=== TIẾN HÀNH DEBLOAT AN TOÀN ({len(SAFE_DEBLOAT_PACKAGES)} gói) ===\n")
    success_count = 0
    skipped_count = 0

    for pkg, desc in SAFE_DEBLOAT_PACKAGES:
        if pkg not in installed:
            print(f"[ĐÃ BỎ QUA] {pkg} (không tồn tại hoặc đã gỡ)")
            skipped_count += 1
            continue

        res = subprocess.run(
            ["adb", "shell", f"pm uninstall -k --user 0 {pkg}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        out = res.stdout.strip()
        if "Success" in out:
            print(f"[ĐÃ GỠ] {pkg} - {desc}")
            success_count += 1
        else:
            print(f"[LỖI] {pkg}: {out} {res.stderr.strip()}")

    print(f"\n Hoàn tất: Đã gỡ {success_count} gói, Bỏ qua {skipped_count} gói.")

if __name__ == "__main__":
    main()

