# JA Translate

[![Version](https://img.shields.io/badge/version-1.2.3-blue.svg)](https://github.com/jatechvn/JA_Translate/releases)
[![Flutter](https://img.shields.io/badge/flutter-3.x-teal.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Windows%20x64-lightgrey.svg)](https://github.com/jatechvn/JA_Translate)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](ABOUT.txt)

> **JA Translate** là phần mềm dịch thuật cao cấp và tra cứu Pinyin tiếng Trung trên Windows x64, tích hợp AI ngoại tuyến (Local LLM via `llama-server`) và công nghệ nhận diện hình ảnh OCR đa tầng thông minh.

---

## ✨ Tính năng nổi bật

- 💎 **Fluent Frosted Glass Bento UI:** Thiết kế hiện đại chuẩn phong cách Bento Grid từ `flutter_ui_template`, nền kính sữa mờ cao cấp chống chói, tối ưu WCAG AAA và hỗ trợ hiệu ứng DWM Aero / Acrylic native.
- ⚡ **Tối ưu hóa Năng lượng (Flutter Power Optimizer):** Triệt tiêu hoàn toàn nhịp vẽ GPU và AnimationController khi ứng dụng mất focus, thu nhỏ Taskbar hoặc ẩn trong Tray. Tự động tạm dừng hoạt ảnh làm mờ nặng khi nhàn rỗi > 12s, đưa GPU Engine về ~0.0%.
- 🔄 **1-Tap Quick AI Engine Switcher:** Hoán đổi tức thì giữa Local AI (Qwen GGUF Offline) và Cloud AI (NVIDIA NIM Gateway) ngay từ thanh tiêu đề.
- ⚡ **Offline Local AI Engine:** Tích hợp backend `llama-server` chạy mô hình Qwen 2.5 1.5B Instruct siêu nhẹ, dịch ngoại tuyến 100% riêng tư không cần Internet.
- 🌐 **Hỗ trợ Đa ngôn ngữ (VI / ENG / CN):** Chuyển đổi giao diện 1-chạm giữa Tiếng Việt, Tiếng Anh và Tiếng Trung với từ điển đầy đủ không sót ký tự.
- 🔒 **Bảo toàn trạng thái Tab (Tab State Preservation):** Giữ nguyên văn bản, dữ liệu dịch và con trỏ khi chuyển qua lại giữa các màn hình nhờ kiến trúc `IndexedStack`.
- 📥 **Tự động tải Model trực tiếp:** Hộp thoại tải mô hình GGUF trực tiếp vào thư mục app với tiến trình % thời gian thực.
- 📸 **Screen Snip & Vision OCR:** Chụp màn hình nhanh bằng phím tắt Windows `Win + Shift + S` và nhận diện chữ tự động bằng Tesseract OCR kết hợp Vision AI.
- 🀄 **Phiên âm Pinyin thông minh:** Chuyển đổi chữ Hán sang Pinyin chuẩn kèm thanh điệu phục vụ học tập và dịch thuật chuyên sâu.
- 🚀 **Portable & Sạch sẽ:** Không cần cài đặt rườm rà, giải nén và chạy ngay lập tức.

---

## 🚀 Cài đặt nhanh

1. Tải bản phát hành mới nhất từ thư mục `dist/` hoặc [Releases](https://github.com/jatechvn/JA_Translate/releases): `JA_Translate_v1.2.3_Windows_x64.zip`.
2. Giải nén file `.zip` vào thư mục bất kỳ.
3. Chạy file `ja_translate.exe` để bắt đầu sử dụng.

---

## 📝 Thay đổi gần đây (v1.2.3)

- **Chuẩn hóa Tiêu đề Cửa sổ & Windows Metadata (App Name Alignment):**
  - Khởi tạo cửa sổ trong `windows/runner/main.cpp` với tiêu đề `JA Translate` thay vì tên file exe `ja_translate`.
  - Cập nhật PE Metadata (`Runner.rc`): `FileDescription` và `ProductName` đổi thành `JA Translate`, giúp Windows Task Manager và Alt+Tab hiển thị đúng tên app thương hiệu.
  - Cố định tiêu đề cửa sổ `JA Translate  v1.2.3` trên mọi phiên bản Windows.
- **Tối ưu hóa năng lượng tự động:** Triệt tiêu nhịp vẽ GPU khi ẩn/nhàn rỗi (Power Optimizer).
- **Kiểm thử tự động toàn diện:** 45/45 tests passed 100%.

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
