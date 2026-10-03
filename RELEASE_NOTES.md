TAG=v1.2.2
TITLE=JA Translate v1.2.2 — Tối Ưu Hóa Năng Lượng & Giảm Tải GPU/CPU Khi Ẩn/Nhàn Rỗi
BODY=
## JA Translate v1.2.2 — Tối Ưu Hóa Năng Lượng & Giảm Tải GPU/CPU Khi Ẩn/Nhàn Rỗi

- **Tối ưu hóa năng lượng Flutter Desktop (Flutter Power Optimizer):** Triệt tiêu hoàn toàn lượng tiêu thụ GPU/CPU không cần thiết khi ứng dụng ẩn trong khay hệ thống (System Tray), thu nhỏ xuống Taskbar, mất tiêu điểm (Unfocused), hoặc nhàn rỗi (>12s).
- **Bộ điều phối năng lượng trung tâm (`PowerCoordinator`):** Quản lý tập trung các trạng thái `isVisible`, `isFocused`, `isMinimized`, và bộ đếm nhàn rỗi `isIdle` 12 giây.
- **Cổng `TickerMode` toàn cục:** Bao bọc cây giao diện gốc `MaterialApp.builder` bằng `TickerMode(enabled: isUiActive)`, lập tức ngắt toàn bộ AnimationController và nhịp vẽ GPU khi ứng dụng bị che khuất.
- **Tiết kiệm tải 85px Gaussian Blur (`MeshOrb`):** 3 khối cầu nền tự động tạm dừng chuyển động khi người dùng nhàn rỗi > 12s, đưa mức chiếm dụng GPU Engine về ~0.0% mà giao diện vẫn sắc nét và phản hồi tức thì khi di chuột.
- **Đồng bộ vòng đời Windows chuẩn xác:** Lắng nghe đầy đủ `onWindowFocus`, `onWindowBlur`, `onWindowMinimize`, `onWindowRestore` và ngắt UI tức thời khi đóng vào khay hệ thống.
- **Session Epoch & Tối ưu bộ thăm dò:** Bảo vệ callback bất đồng bộ của `AsymmetricMarqueeText` và bỏ qua thăm dò `_aiStatusTimer` khi cửa sổ không hoạt động.
- **Bảo toàn 100% tác vụ nghiệp vụ nền:** Tiến trình dịch cục bộ (Local Qwen / Opus MT), phím tắt toàn cầu (`Alt+Q`, `Alt+S`) và kiểm tra cập nhật LAN OTA tiếp tục hoạt động liên tục trong nền.
- **Kiểm thử tự động toàn diện:** Bổ sung `test/power_coordinator_test.dart`, nâng tổng số bài kiểm thử lên 45/45 tests (100% pass).

### Cài đặt
Giải nén toàn bộ `JA_Translate_v1.2.2_Windows_x64.zip` và chạy `ja_translate.exe`. Xem `USERGUIDE.md` trong gói để biết thêm chi tiết.
