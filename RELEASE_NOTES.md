TAG=v1.2.0
TITLE=JA Translate v1.2.0 — Remake Giao Diện Bento Frosted Glass, Đổi Nhanh AI & Khắc Phục Lỗi Chuyển Tab
BODY=
## JA Translate v1.2.0 — Remake Giao Diện Bento Frosted Glass, Đổi Nhanh AI & Khắc Phục Lỗi Chuyển Tab

- **Giao diện Frosted Glass Bento Grid cao cấp:** Thiết kế lại toàn bộ hệ thống giao diện theo chuẩn `flutter_ui_template`. Nâng độ đục bề mặt lên 86% loại bỏ hoàn toàn hiện tượng chữ nền xuyên thấu, đạt chuẩn tương phản cao WCAG AAA trên cả Light và Dark Mode.
- **Nút hoán đổi nhanh AI (Quick Switcher):** Capsule trên TopBar cho phép chuyển đổi 1-chạm giữa Local AI (Qwen GGUF Offline) và Cloud AI (NVIDIA NIM Gateway), kèm thông báo Toast nổi tức thời.
- **Khắc phục lỗi mất dữ liệu khi chuyển Tab:** Chuyển sang cơ chế `IndexedStack` và `AutomaticKeepAliveClientMixin`, giữ nguyên vẹn 100% văn bản, bản dịch và vị trí thao tác khi chuyển qua lại giữa các tab.
- **Icon thương hiệu mới:** Tạo file `app_icon.ico` chuẩn Windows đa phân giải từ logo bóng kính cao cấp, đồng bộ trên Taskbar, Desktop Shortcut và Control Panel.
- **Bento AI Studio:** Tối ưu hóa bảng thông số phần cứng, RAM và dung lượng mô hình Qwen GGUF nhúng sẵn.
- **Đồng bộ tài liệu & kiểm thử:** Đạt 31/31 unit & widget tests pass, đồng bộ About, User Guide, README, CHANGELOG.md, ABOUT.txt.

### Cài đặt
Giải nén toàn bộ `JA_Translate_v1.2.0_Windows_x64.zip` và chạy `ja_translate.exe`. Xem `USERGUIDE.md` trong gói để biết thêm chi tiết.
