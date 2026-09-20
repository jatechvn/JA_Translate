# Changelog - JA Translate

Tất cả các thay đổi quan trọng của dự án JA Translate sẽ được ghi lại trong tài liệu này.

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
