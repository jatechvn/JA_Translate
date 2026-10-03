TAG=v1.2.4
TITLE=JA Translate v1.2.4 — Khắc Phục Cập Nhật LAN OTA & Tối Ưu Quy Trình Thoát Sạch Ứng Dụng
BODY=
## JA Translate v1.2.4 — Khắc Phục Cập Nhật LAN OTA & Tối Ưu Quy Trình Thoát Sạch Ứng Dụng

- **Khắc phục Nghẽn Kiểm Tra Bản Mới OTA (`ota_update_service.dart`):**
  - Quét thông minh song song `version.json` và toàn bộ các gói zip trên máy chủ, tự động chọn phiên bản cao nhất giữa chúng. Không bao giờ bị nghẽn bởi file `version.json` cũ trên máy chủ nữa.
- **Tự Động Hóa Sinh Manifest `version.json` (`package_dist.ps1`):**
  - Tự động tạo và cập nhật file `version.json` mỗi khi đóng gói và đồng bộ lên máy chủ LAN.
- **Tối Ưu Quy Trình Thoát Sạch & Quản Lý Cửa Sổ (Clean Process Termination):**
  - Tự động giải phóng `llama-server.exe` và thoát toàn diện với `exit(0)`. Triệt tiêu hoàn toàn tình trạng tiến trình vẫn chạy ngầm trong Windows Task Manager sau khi đóng cửa sổ.
  - Bổ sung tùy chọn Cài đặt: Cho phép người dùng linh hoạt bật *"Thu nhỏ vào khay hệ thống khi đóng"* nếu muốn duy trì phím tắt `Alt+Q` (Mở nhanh) và `Alt+S` (Chụp màn hình dịch). Mặc định là thoát hẳn ứng dụng khi bấm nút X.
- **Kiểm thử tự động toàn diện:** 46/46 tests passed 100%, static analysis không lỗi (`No issues found!`).

### Cài đặt
Giải nén toàn bộ `JA_Translate_v1.2.4_Windows_x64.zip` và chạy `ja_translate.exe`. Xem `USERGUIDE.md` trong gói để biết thêm chi tiết.

