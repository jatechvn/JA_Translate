# Changelog - JA Translate

Tất cả các thay đổi quan trọng của dự án JA Translate sẽ được ghi lại trong tài liệu này.

## [v1.2.5] - 2026-10-03

### 📋 Sao Chép Tiếng Trung Sạch Pinyin (Clean Chinese Copy)
- **Sao Chép Chữ Hán Thuần Túy Trên Thẻ Kết Quả (Output):**
  - Tự động nhận diện và cắt bỏ khối chú thích phiên âm (`\n\nPinyin:\n...`) qua hàm thuần `TranslateLogic.cleanChineseForCopy()`.
  - Khi bấm nút Copy ở thẻ Kết quả, clipboard chỉ lưu trữ chữ Hán / văn bản dịch gốc, không còn lẫn Pinyin.
- **Bổ Sung Nút Copy Trên Thanh Công Cụ Nhập Liệu (Input):**
  - Thêm nút Copy (`Icons.copy_rounded`) trên thanh công cụ thẻ Input giúp người dùng sao chép nhanh văn bản nguồn một chạm.
  - Tự động làm sạch khối Pinyin nếu văn bản nguồn có chứa phiên âm.
- **Đồng Bộ Bộ Lọc Toàn Diện:**
  - Tích hợp bộ lọc làm sạch Pinyin vào màn hình Lịch sử dịch thuật (`translation_history_view.dart`) và cửa sổ chính (`main_window.dart`).

### 🖼️ Hỗ Trợ Dán Ảnh Trực Tiếp Từ Clipboard (`Ctrl + V` & Nút Paste)
- **Dán Ảnh Thông Minh Qua Phím Tắt `Ctrl + V`:**
  - Tích hợp `FocusNode` bắt phím trên ô `TextField` nhập liệu: Tự động phát hiện dữ liệu hình ảnh trong Clipboard (ảnh chụp màn hình từ `Win + Shift + S`, `PrintScreen`, copy ảnh từ trình duyệt web, hoặc `Ctrl + C` tệp ảnh từ Windows Explorer `CF_HDROP`).
  - Tự động chặn thao tác dán text rác vào ô văn bản, lưu tệp ảnh tạm, đính kèm vào danh sách ảnh (`_attachedImages`), hiển thị Toast thông báo nổi và tự động kích hoạt tiến trình OCR/Vision dịch ngay lập tức.
  - Nếu clipboard là văn bản thuần túy, thao tác dán hoạt động bình thường mượt mà tại vị trí con trỏ.
  - Xử lý phím tắt `Ctrl + V` ngay cả khi con trỏ chuột nằm ngoài ô văn bản.
- **Nâng Cấp Nút Dán (Paste) Trên Thanh Công Cụ Input:**
  - Ưu tiên kiểm tra định dạng hình ảnh từ Clipboard trước tiên. Nếu có ảnh $\rightarrow$ đính kèm và dịch; nếu là text $\rightarrow$ dán text.
- **Đa Ngôn Ngữ:**
  - Bổ sung thông báo Toast nổi `toast_image_pasted` chuẩn hóa 3 ngôn ngữ: VI ("Đã dán ảnh từ bộ nhớ tạm"), ENG ("Pasted image from clipboard"), CN ("已从剪贴板粘贴图片").

### 🧪 Kiểm Thử Tự Động & Đối Soát Chất Lượng
- Viết bộ kiểm thử chuyên biệt `test/chinese_clean_copy_test.dart` (6 bài test kiểm chứng việc lọc Pinyin và phát hiện Clipboard ảnh).
- Cập nhật bộ kiểm thử từ điển `test/complete_localization_test.dart`.
- Toàn bộ **53/53 bài kiểm thử** tự động đều vượt qua thành công, `flutter analyze` 0 warnings / 0 issues.

### 📦 Phát Hành
- Đồng bộ version 1.2.5+8 trong `pubspec.yaml`, `constants.dart`, `Runner.rc`, `ABOUT.txt`, `USERGUIDE.md`, `README.md`, `RELEASE_NOTES.md`.
- Đóng gói bản phát hành Windows x64 mới nhất vào thư mục `dist/` kèm file nén `JA_Translate_v1.2.5_Windows_x64.zip`, `version.json` và mã băm `dist/SHA256SUMS.txt`.

---

## [v1.2.4] - 2026-10-03

### 🔄 Khắc Phục Cơ Chế Cập Nhật LAN OTA & Tự Động Hóa Manifest
- **Khắc phục Nghẽn Kiểm Tra Bản Mới (`ota_update_service.dart`):**
  - Cải tiến thuật toán phát hiện gói: Luôn kiểm tra song song `version.json` VÀ quét toàn bộ danh sách gói nén `.zip` trong thư mục máy chủ.
  - So sánh và tự động chọn gói có phiên bản cao nhất giữa chúng (`latestZipPkg.version > jsonPkg.version ? latestZipPkg : jsonPkg`), triệt tiêu 100% tình huống file `version.json` cũ vô tình chặn client cập nhật lên bản zip mới hơn.
- **Tự Động Hóa Sinh Manifest `version.json` (`package_dist.ps1`):**
  - Tự động trích xuất release notes, sinh file `version.json` đồng bộ trực tiếp vào `dist/` và gói ứng dụng sẵn sàng phục vụ client LAN OTA.
- **Cập Nhật Ngay Metadata Server LAN:**
  - Đồng bộ lại `version.json` trên máy chủ `\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Translate`.

### 🛡️ Tối Ưu Quy Trình Thoát Sạch & Quản Lý Cửa Sổ (Clean Process Termination)
- **Quy Trình Thoát Sạch Toàn Diện (`DesktopService.quitApplication`):**
  - Tự động ngắt sạch tiến trình nền `llama-server.exe` thông qua `taskkill`, giải phóng handle cửa sổ native và cưỡng chế `exit(0)`.
  - Triệt tiêu hoàn toàn lỗi ứng dụng đã đóng cửa sổ nhưng tiến trình `ja_translate.exe` vẫn tồn tại chạy ngầm trong Windows Task Manager.
- **Tùy Chọn Khay Hệ Thống Linh Hoạt (`minimize_to_tray_on_close`):**
  - Mặc định khi bấm nút `X`: Ứng dụng thoát sạch 100% và biến mất khỏi Task Manager.
  - Bổ sung tùy chọn switch toggle trong Cài đặt Chung: Cho phép người dùng chủ động chọn thu nhỏ xuống khay Taskbar nếu muốn duy trì phím tắt `Alt+Q` (Mở nhanh) và `Alt+S` (Chụp màn hình dịch).
  - Bản địa hóa đầy đủ 3 ngôn ngữ (VI / ENG / CN) cho tính năng mới.

### 🧪 Kiểm Thử Tự Động Toàn Diện
- Bổ sung test hồi quy `test/ota_update_service_test.dart` kiểm chứng khả năng vượt qua file `version.json` cũ khi có bản zip mới.
- Toàn bộ **46/46 unit & widget tests** passed 100%, Flutter analyze `No issues found!`.

### 📦 Phát hành
- Đồng bộ version 1.2.4+7 trong `pubspec.yaml`, `constants.dart`, `Runner.rc`, `ABOUT.txt`, `USERGUIDE.md`, `README.md`, `RELEASE_NOTES.md`.
- Đóng gói bản phát hành Windows x64 mới nhất vào thư mục `dist/` kèm file nén `JA_Translate_v1.2.4_Windows_x64.zip`, `version.json` và mã băm `dist/SHA256SUMS.txt`.

---

## [v1.2.3] - 2026-10-03

### 🪟 Chuẩn Hóa Tiêu Đề Cửa Sổ & Metadata Windows Native (App Name Alignment)
- **Chuẩn hóa Tiêu đề Cửa sổ Native Win32:**
  - Khởi tạo cửa sổ trong `windows/runner/main.cpp` với tiêu đề chính xác `L"JA Translate"` thay vì chuỗi tên tệp nhị phân `L"ja_translate"`.
  - Cập nhật `lib/main.dart` và `lib/modules/window_helper.dart` luôn thiết lập tiêu đề cửa sổ đầy đủ `JA Translate  v1.2.3` trên tất cả các phiên bản Windows (Windows 10 & Windows 11), triệt tiêu hoàn toàn hiện tượng thanh tác vụ Windows (Taskbar) hiển thị tên tệp exe `ja_translate`.
- **Đồng bộ Thông tin Định danh PE Metadata (`Runner.rc`):**
  - Cập nhật `FileDescription` từ `ja_translate` thành `JA Translate`: Windows Task Manager hiển thị rõ ràng tên ứng dụng "JA Translate" trong danh sách tiến trình (Processes / Details tab).
  - Cập nhật `ProductName` và `InternalName` thành `JA Translate`: Thông tin chi tiết thuộc tính tệp (File Properties Details) và cửa sổ chuyển đổi `Alt + Tab` hiển thị đồng bộ tên thương hiệu.
  - Cập nhật `CompanyName` và `LegalCopyright` thành `JA-Tech System`.

### 📦 Phát hành
- Đồng bộ version 1.2.3+6 trong `pubspec.yaml`, `constants.dart`, `Runner.rc`, `ABOUT.txt`, `USERGUIDE.md`, `README.md`, `RELEASE_NOTES.md`.
- Đóng gói bản phát hành Windows x64 mới nhất vào thư mục `dist/` kèm file nén `JA_Translate_v1.2.3_Windows_x64.zip` và mã băm `dist/SHA256SUMS.txt`.

---

## [v1.2.2] - 2026-10-03

### ⚡ Tối Ưu Hóa Năng Lượng & Giảm Tải GPU/CPU (Flutter Desktop Power Optimizer)
- **Bộ Điều Phối Năng Lượng Tập Trung (`PowerCoordinator`):**
  - Quản lý tập trung các trạng thái `isVisible`, `isFocused`, `isMinimized`, và bộ đếm nhàn rỗi `isIdle` (mặc định 12 giây không tương tác chuột/phím).
  - Phân định rõ 2 chính sách: `isUiActive` (cho render và TickerMode) và `isDecorActive` (cho hoạt ảnh nền nặng).
- **Cổng `TickerMode` Toàn Cục:**
  - Bao bọc toàn bộ cây widget trong `MaterialApp.builder` bằng `TickerMode(enabled: power.isUiActive)`.
  - Triệt tiêu 100% nhịp vẽ GPU và AnimationController khi ứng dụng mất focus (làm việc app khác), thu nhỏ xuống Taskbar, hoặc ẩn vào System Tray.
- **Tiết Kiệm Tải 85px Gaussian Blur (`MeshOrb`):**
  - Tự động tạm dừng chuyển động làm mờ nặng (`_controller.stop()`) khi người dùng nhàn rỗi quá 12 giây, đưa mức sử dụng GPU Engine về ~0.0%.
  - Thức tỉnh tức thì khi người dùng di chuột hoặc nhấn phím thông qua `Listener` bắt tương tác người dùng.
- **Đồng Bộ Vòng Đời Cửa Sổ Windows (`DesktopService`):**
  - Lắng nghe và xử lý chuẩn xác `onWindowFocus`, `onWindowBlur`, `onWindowMinimize`, `onWindowRestore`.
  - Đồng bộ tức thời trạng thái ẩn ngay khi người dùng bấm nút Close (`onWindowClose`), kèm cơ chế tự sửa lỗi nếu lệnh native hide thất bại.
- **Session Epoch & Tối Ưu Bộ Thăm Dò:**
  - Bổ sung session epoch bảo vệ callback bất đồng bộ trong `AsymmetricMarqueeText`, loại bỏ hoàn toàn timer trôi nổi.
  - Tối ưu bộ thăm dò `_aiStatusTimer` (4s) trong `DashboardShell`: tự động bỏ qua khi cửa sổ không active, và kích hoạt thăm dò tức thì khi active trở lại.
- **Bảo Toàn 100% Tác Vụ Nền:**
  - Giữ nguyên vẹn tiến trình dịch cục bộ (Local Qwen / Opus MT), lắng nghe Clipboard, phím tắt toàn cầu (`Alt+Q`, `Alt+S`) và kiểm tra cập nhật mạng nội bộ LAN OTA.

### 🧪 Kiểm Thử Tự Động & Độ Tin Cậy
- Bổ sung bộ kiểm thử hồi quy chuyên sâu `test/power_coordinator_test.dart` bao quát 6 kịch bản vòng đời và cách ly tác vụ nền.
- Nâng tổng số bài kiểm thử tự động lên **45/45 tests passed 100%**.

### 📦 Phát hành
- Đồng bộ version 1.2.2+5 trong `pubspec.yaml`, `constants.dart`, `Runner.rc`, `ABOUT.txt`, `USERGUIDE.md`, `README.md`, `RELEASE_NOTES.md`.
- Đóng gói bản phát hành Windows x64 mới nhất vào thư mục `dist/` kèm file nén `JA_Translate_v1.2.2_Windows_x64.zip` và mã băm `dist/SHA256SUMS.txt`.

---

## [v1.2.1] - 2026-10-02

### 🌐 Chuẩn hóa Đa ngôn ngữ (VI / ENG / CN) Toàn diện
- **Loại bỏ 100% chuỗi ký tự cố định (Hardcoded Strings):**
  - Màn hình Lịch sử Dịch: Toàn bộ hộp thoại xóa lịch sử (`history_clear_*`), bộ lọc đã lưu (`history_saved_filter`) và thông báo khôi phục (`history_restored_toast`) chuyển sang từ điển động.
  - Màn hình AI Studio: Thẻ Bento phần cứng, RAM, kích thước ngữ cảnh, huy hiệu trạng thái mô hình và nút chuyển nhanh Cloud AI được đồng bộ 3 ngôn ngữ.
  - Màn hình Dịch Tài Liệu: Tích hợp hệ thống quản lý trạng thái dịch động `_statusKey` (`doc_*`), tự động chuyển ngữ theo thời gian thực khi đổi ngôn ngữ hiển thị mà không làm đứt mạch tiến trình.
  - Màn hình Dịch Văn Bản: Bổ sung hỗ trợ đa ngữ cho cảnh báo microphone, tooltip đính kèm ảnh, nhãn ảnh và bộ đếm ký tự.
  - Bảng Cài đặt Nhanh & Hộp thoại About: Toàn bộ mô tả tính năng tự động dịch, pinyin, phông PDF và bảng 9 phím tắt hệ thống được đồng bộ qua hệ thống `shortcut_*` và `about_*`.
  - Bộ điều khiển GlassDropdown & TopBar: Gợi ý tìm kiếm, trạng thái trống và tooltip/toast chuyển đổi AI tức thời tuân thủ chuẩn đa ngôn ngữ.

### 🧪 Kiểm thử & Bảo toàn Ổn định
- **Bổ sung bộ test tự động chuyên sâu:**
  - `test/complete_localization_test.dart`: Đối soát tự động tất cả các khóa dịch thuật trên cả 3 ngôn ngữ và kiểm thử cơ chế nội suy chuỗi tham số `%s`, `%d`.
  - `test/localization_regression_test.dart`: Kiểm tra tiến trình dịch tài liệu và thanh tiêu đề TopBar.
  - Toàn bộ 35/35 unit & widget test chạy thành công 100%.

### 📦 Phát hành
- Đồng bộ version 1.2.1+4 trong `pubspec.yaml`, `constants.dart`, `Runner.rc`, `ABOUT.txt`, `USERGUIDE.md`, `README.md`, `RELEASE_NOTES.md`.
- Đóng gói chuẩn portable x64 vào `dist/` kèm file nén `JA_Translate_v1.2.1_Windows_x64.zip` và mã băm `dist/SHA256SUMS.txt`.

---

## [v1.2.0] - 2026-10-01

### 🚀 Nâng cấp & Tính năng mới
- **Tái thiết kế toàn diện giao diện Fluent Frosted Glass (Bento Grid):**
  - Chuyển đổi toàn bộ UI theo phong cách Bento Grid & Frosted Glass từ `flutter_ui_template`.
  - Nâng cấp độ đục card (`cardBg`) lên 86% kết hợp lớp phủ sữa mờ (frosted milk glass) ngăn ngừa 100% hiện tượng văn bản phía sau màn hình/cửa sổ khác chiếu xuyên qua làm nhòe chữ.
  - Tối ưu bảng màu WCAG AAA High Contrast cho cả hai chế độ Sáng (Light) và Tối (Dark).
  - Tương thích mượt mà hiệu ứng làm mờ cửa sổ Windows DWM (Aero trên Windows 10 và Mica / Acrylic trên Windows 11).
- **Bộ hoán đổi nhanh AI Cục bộ / Đám mây (1-Tap Quick Engine Switcher):**
  - Nâng cấp nút Dynamic Island Capsule trên thanh tiêu đề thành bộ chuyển đổi tức thì giữa Local AI (Qwen GGUF Offline) và Cloud AI (NVIDIA NIM Gateway).
  - Nhấp chuột 1 lần (Tap) để đổi nguồn AI tức thì không gián đoạn công việc, hiển thị Toast xác nhận nổi và tự động lưu cấu hình.
  - Nhấp giữ (Long Press) để mở sâu AI Engine Studio.
- **Biểu tượng thương hiệu & Icon Windows mới:**
  - Nhận diện thương hiệu mới từ `assets/logo.png`, tạo file icon chuẩn `windows/runner/resources/app_icon.ico` đa phân giải 7 kích thước (`16x16` đến `256x256`).
  - Tích hợp logo đồng bộ trên Taskbar, Desktop Shortcut, Start Menu, TopBar và Hộp thoại Giới thiệu (About).
- **Bố cục lại AI Engine Studio chuyên nghiệp:**
  - Thiết kế Bento 3 tầng trực quan: Thẻ điều khiển mô hình (Model Control), Lưới phần cứng & kiến trúc RAM/Context (Hardware Bento Grid), và Cầu nối Cloud AI.

### 🐛 Sửa lỗi & Tối ưu hóa
- **Khắc phục lỗi mất văn bản khi chuyển Tab (Tab State Preservation):**
  - Chuyển đổi thanh điều hướng trung tâm từ `AnimatedSwitcher` sang `IndexedStack` duy trì toàn bộ 4 tab (`Text`, `Documents`, `History`, `AI Studio`) liên tục trong widget tree dưới trạng thái `Offstage`.
  - Tích hợp `AutomaticKeepAliveClientMixin` và hàm đồng bộ khôi phục `restoreText()` từ Lịch sử, bảo toàn 100% văn bản đã nhập và kết quả dịch khi chuyển đổi qua lại.
- **Khắc phục tràn bố cục (RenderFlex Overflow):** Sửa lỗi tràn 11px ở tiêu đề Document Translation View trên màn hình hẹp.
- **Bổ sung bộ test tự động toàn diện:** Nâng tổng số ca kiểm thử lên 31 tests (100% pass) kiểm tra toàn vẹn dịch thuật, trạng thái động cơ, đổi ngôn ngữ và bảo toàn dữ liệu tab.

### 📦 Phát hành
- Đồng bộ version 1.2.0+3 trong `pubspec.yaml`, `constants.dart`, `Runner.rc`, `ABOUT.txt`, `USERGUIDE.md`, `README.md`, `RELEASE_NOTES.md`.
- Đóng gói chuẩn portable x64 vào `dist/` kèm file nén `JA_Translate_v1.2.0_Windows_x64.zip` và mã băm `dist/SHA256SUMS.txt`.

---

## [v1.1.0] - 2026-09-21

### 🚀 Nâng cấp & Tính năng mới
- **Tích hợp Offline Local AI (llama-server + Qwen 2.5):** Hỗ trợ dịch ngoại tuyến an toàn, tốc độ cao mà không phụ thuộc vào Ollama cài ngoài. Tự động khởi chạy backend `llama-server.exe` nội bộ và giao tiếp qua OpenAI-compatible API (`127.0.0.1:8080`).
- **Trình tải mô hình tự động trực tiếp trong ứng dụng:** Cho phép tải mô hình Qwen 2.5 1.5B Instruct GGUF trực tiếp về thư mục `models/` của app với thanh tiến trình tải chi tiết, hiển thị % và tốc độ tải, hỗ trợ hủy tải an toàn.
- **Hệ thống chụp màn hình & OCR đa tầng (Multi-tier Vision):** 
  - Hỗ trợ dịch ảnh trực tiếp từ màn hình thông qua Windows Snipping Tool (`Win + Shift + S`) và file ảnh.
  - Cơ chế nhận diện ký tự quang học đa tầng thông minh: Tesseract OCR cục bộ fallback kết hợp Vision AI (Cloud / Local) để trích xuất văn bản chữ Hán, tiếng Anh, tiếng Việt chính xác.
- **Giao diện Glass Dropdown cao cấp:** Thiết kế lại bộ chọn model và ngôn ngữ theo phong cách Glassmorphism và bảng màu chuẩn `flutter_ui_template` (JA-Tech Design System), loại bỏ dropdown mặc định thô ráp.
- **Cải tiến thông báo thông minh:** Khi thiếu model cục bộ, app tự động gợi ý tải model hoặc mở hộp thoại cấu hình Cloud thay vì hiển thị cảnh báo lỗi khô khan.

### 🐛 Sửa lỗi & Tối ưu hóa
- **Khắc phục lỗi Windows Screen Snipping:** Sửa lỗi xung đột cửa sổ khiến phím tắt Windows Screen Snip (`Win + Shift + S`) bị đơ hoặc không phản hồi.
- **Khắc phục lỗi ẩn Taskbar khi hủy chụp màn hình:** Đảm bảo cửa sổ chính luôn khôi phục hiển thị và giữ trạng thái trên Taskbar khi người dùng hủy thao tác chụp vùng màn hình.
- **Tối ưu bố cục thanh tiêu đề (Window Titlebar):** Điều chỉnh khoảng cách nút đóng [X] và thanh cuộn giúp thao tác đóng/mở cửa sổ thoải mái, không bị click nhầm.
- **Cải thiện hiển thị tiến trình tải:** Nâng cấp dialog tải model luôn hiển thị nổi bật trên giao diện, không bị che khuất bởi các widget nền.

### 📦 Phát hành
- Đồng bộ version 1.1.0+2 trong `pubspec.yaml`, `constants.dart`, `Runner.rc`, `ABOUT.txt`, `USERGUIDE.md`, `README.md`, `RELEASE_NOTES.md`.
- Đóng gói chuẩn portable x64 vào `dist/` kèm file nén `JA_Translate_v1.1.0_Windows_x64.zip` và mã băm `dist/SHA256SUMS.txt`.

---

## [v1.0.0] - 2026-09-18

### 🚀 Khởi tạo dự án ban đầu
- Khởi tạo kiến trúc Flutter Desktop cho Windows với Fluent UI / Glassmorphism.
- Hỗ trợ dịch thuật văn bản cơ bản, chuyển đổi Pinyin cho tiếng Trung Quốc (Phồn thể / Giản thể).
- Tích hợp Text-to-Speech (TTS) và Speech-to-Text (STT) cơ bản.
