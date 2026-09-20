# JA Translate

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/jatechvn/JA_Translate/releases)
[![Flutter](https://img.shields.io/badge/flutter-3.x-teal.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Windows%20x64-lightgrey.svg)](https://github.com/jatechvn/JA_Translate)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](ABOUT.txt)

> **JA Translate** là phần mềm dịch thuật cao cấp và tra cứu Pinyin tiếng Trung trên Windows x64, tích hợp AI ngoại tuyến (Local LLM via `llama-server`) và công nghệ nhận diện hình ảnh OCR đa tầng thông minh.

---

## ✨ Tính năng nổi bật

- ⚡ **Offline Local AI Engine:** Tích hợp backend `llama-server` chạy mô hình Qwen 2.5 1.5B Instruct siêu nhẹ, dịch ngoại tuyến 100% riêng tư không cần Internet.
- 📥 **Tự động tải Model trực tiếp:** Hộp thoại tải mô hình GGUF trực tiếp vào thư mục app với tiến trình % thời gian thực.
- 📸 **Screen Snip & Vision OCR:** Chụp màn hình nhanh bằng phím tắt Windows `Win + Shift + S` và nhận diện chữ tự động bằng Tesseract OCR kết hợp Vision AI.
- 🀄 **Phiên âm Pinyin thông minh:** Chuyển đổi chữ Hán sang Pinyin chuẩn kèm thanh điệu phục vụ học tập và dịch thuật chuyên sâu.
- 💎 **Fluent Glassmorphism UI:** Thiết kế hiện đại chuẩn phong cách JA-Tech Design System, hỗ trợ Dark Mode và hiệu ứng Mica/Acrylic.
- 🚀 **Portable & Sạch sẽ:** Không cần cài đặt rườm rà, giải nén và chạy ngay lập tức.

---

## 🚀 Cài đặt nhanh

1. Tải bản phát hành mới nhất từ thư mục `dist/` hoặc [Releases](https://github.com/jatechvn/JA_Translate/releases): `JA_Translate_v1.1.0_Windows_x64.zip`.
2. Giải nén file `.zip` vào thư mục bất kỳ.
3. Chạy file `ja_translate.exe` để bắt đầu sử dụng.

---

## 📝 Thay đổi gần đây (v1.1.0)

- **Tích hợp Offline Local AI:** Chạy model `qwen2.5-1.5b-instruct-q4_k_m.gguf` nội bộ qua llama-server, loại bỏ phụ thuộc Ollama bên ngoài.
- **Trình tải model in-app:** Tự động hỏi tải model hoặc mở cài đặt Cloud với UI trực quan.
- **Hệ thống Vision OCR:** Hỗ trợ chụp màn hình và trích xuất chữ viết đa ngôn ngữ.
- **Sửa lỗi Taskbar & Hotkey:** Khắc phục triệt để lỗi mất cửa sổ Taskbar khi hủy chụp màn hình và xung đột phím tắt Windows Snipping Tool.
- **Đồng bộ giao diện Glass Dropdown:** Tinh chỉnh các menu chọn theo mẫu `flutter_ui_template`.

---

## 🛠️ Phát triển & Biên dịch

Yêu cầu môi trường:
- Flutter SDK `>=3.0.0`
- Visual Studio 2022 (C++ Desktop Development)
- Python 3.10+ (cho OCR phụ trợ)

```powershell
# Cài đặt dependencies
flutter pub get

# Kiểm tra mã nguồn
flutter analyze

# Chạy ở chế độ Debug
flutter run -d windows

# Đóng gói bản phát hành
powershell -ExecutionPolicy Bypass -File .\package_dist.ps1
```

---

## 📄 Bản quyền

Phát triển bởi **JA Tech System** ([https://jatechvn.github.io/](https://jatechvn.github.io/)). Mọi quyền được bảo lưu.
