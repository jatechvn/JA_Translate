# JA Translate

[![Version](https://img.shields.io/badge/version-1.2.5-blue.svg)](https://github.com/jatechvn/JA_Translate/releases)
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
- 📋 **Sao chép Tiếng Trung thuần túy:** Tự động loại bỏ phần phiên âm Pinyin khi sao chép chữ Hán ở thẻ Input, Output hoặc Lịch sử.
- 🖼️ **Dán ảnh trực tiếp từ Clipboard:** Hỗ trợ phím tắt `Ctrl + V` và nút Paste dán thẳng ảnh chụp màn hình, ảnh từ trình duyệt hoặc tệp ảnh từ Explorer để dịch Vision ngay.
- 🚀 **Portable & Sạch sẽ:** Không cần cài đặt rườm rà, giải nén và chạy ngay lập tức.

---

## 🚀 Cài đặt nhanh

1. Tải bản phát hành mới nhất từ thư mục `dist/` hoặc [Releases](https://github.com/jatechvn/JA_Translate/releases): `JA_Translate_v1.2.5_Windows_x64.zip`.
2. Giải nén file `.zip` vào thư mục bất kỳ.
3. Chạy file `ja_translate.exe` để bắt đầu sử dụng.

---

## 📝 Thay đổi gần đây (v1.2.5)

- **Sao Chép Tiếng Trung Sạch Pinyin (Clean Chinese Copy):**
  - Nút Copy ở thẻ Kết quả (Output) và Lịch sử dịch tự động tách bỏ phần chú thích phiên âm (`\n\nPinyin:\n...`), chỉ sao chép chữ Hán thuần túy.
  - Bổ sung nút Copy chuyên dụng trên thanh công cụ của thẻ Nhập liệu (Input), hỗ trợ sao chép nhanh văn bản nguồn và lọc sạch Pinyin.
- **Hỗ Trợ Dán Ảnh Trực Tiếp Từ Clipboard (`Ctrl + V` & Nút Paste):**
  - Tích hợp nhận diện ảnh từ Clipboard khi bấm `Ctrl + V` (trong `TextField` hoặc ngoài cửa sổ) và nút Dán trên thanh công cụ. Hỗ trợ ảnh chụp màn hình, ảnh từ web và file ảnh từ Explorer (`CF_HDROP`).
  - Tự động gắn ảnh vào danh sách đính kèm và kích hoạt tiến trình OCR/Vision dịch ngay.
  - Bổ sung thông báo Toast nổi `toast_image_pasted` đa ngôn ngữ (VI / ENG / CN).
- **Kiểm thử tự động toàn diện:** 53/53 tests passed 100%, Flutter analyze `No issues found!`.

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
