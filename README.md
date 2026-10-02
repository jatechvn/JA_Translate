# JA Translate

[![Version](https://img.shields.io/badge/version-1.2.1-blue.svg)](https://github.com/jatechvn/JA_Translate/releases)
[![Flutter](https://img.shields.io/badge/flutter-3.x-teal.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Windows%20x64-lightgrey.svg)](https://github.com/jatechvn/JA_Translate)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](ABOUT.txt)

> **JA Translate** là phần mềm dịch thuật cao cấp và tra cứu Pinyin tiếng Trung trên Windows x64, tích hợp AI ngoại tuyến (Local LLM via `llama-server`) và công nghệ nhận diện hình ảnh OCR đa tầng thông minh.

---

## ✨ Tính năng nổi bật

- 💎 **Fluent Frosted Glass Bento UI:** Thiết kế hiện đại chuẩn phong cách Bento Grid từ `flutter_ui_template`, nền kính sữa mờ cao cấp chống chói, tối ưu WCAG AAA và hỗ trợ hiệu ứng DWM Aero / Acrylic native.
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

1. Tải bản phát hành mới nhất từ thư mục `dist/` hoặc [Releases](https://github.com/jatechvn/JA_Translate/releases): `JA_Translate_v1.2.1_Windows_x64.zip`.
2. Giải nén file `.zip` vào thư mục bất kỳ.
3. Chạy file `ja_translate.exe` để bắt đầu sử dụng.

---

## 📝 Thay đổi gần đây (v1.2.1)

- **Chuẩn hóa Đa ngôn ngữ Toàn diện (VI/ENG/CN):** Loại bỏ hoàn toàn các chuỗi ký tự cố định, đưa vào từ điển động ở Lịch sử, AI Studio, Dịch tài liệu, Dịch văn bản, Phím tắt và Cài đặt.
- **Nâng cấp độ ổn định & Kiểm thử:** Bổ sung bộ test tự động đối soát toàn bộ từ điển và tiến trình dịch, 35/35 tests pass 100%.
- **Bảo toàn giao diện & Phím tắt:** Đồng bộ 9 phím tắt hệ thống và bảng chẩn đoán About đa ngữ.

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
