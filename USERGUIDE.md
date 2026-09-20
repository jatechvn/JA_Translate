# Hướng dẫn sử dụng JA Translate v1.1.0

Chào mừng bạn đến với **JA Translate v1.1.0** — Phần mềm dịch thuật cao cấp, tích hợp AI ngoại tuyến và nhận diện hình ảnh thông minh dành riêng cho hệ điều hành Windows x64.

---

## 📦 1. Cài đặt & Khởi chạy

1. Tải về file nén `JA_Translate_v1.1.0_Windows_x64.zip`.
2. Giải nén toàn bộ thư mục `JA_Translate_v1.1.0_Windows_x64` ra vị trí thuận tiện (ví dụ: `D:\Apps\JA_Translate` hoặc `C:\JA_Translate`).
3. Khởi chạy tập tin `ja_translate.exe` (hoặc chạy `debug.bat` nếu muốn xem log console).
4. *Lưu ý:* Ứng dụng chạy ở chế độ Portable độc lập, toàn bộ cấu hình và dữ liệu model được lưu ngay trong thư mục của ứng dụng mà không làm rác hệ điều hành.

---

## 🚀 2. Các tính năng chính

### 🌐 2.1. Dịch thuật & Phiên âm Pinyin
- Hỗ trợ dịch đa ngôn ngữ: Tiếng Trung (Giản thể / Phồn thể), Tiếng Việt, Tiếng Anh, Tiếng Nhật, Tiếng Hàn...
- Tự động phiên âm Pinyin kèm dấu thanh điệu chuẩn cho các đoạn văn bản tiếng Hán.
- Tích hợp Text-to-Speech (phát âm giọng đọc bản ngữ) và Speech-to-Text (nhập liệu bằng giọng nói).

### 🤖 2.2. Chế độ AI Cục bộ Ngoại tuyến (Offline Local AI)
- Không cần kết nối Internet và không cần cài đặt Ollama phức tạp.
- Ứng dụng tích hợp sẵn backend `llama-server.exe` nội bộ và hỗ trợ mô hình tối ưu `Qwen 2.5 1.5B Instruct`.
- **Tải model tự động:** Khi chuyển sang chế độ Local AI mà chưa có model, ứng dụng sẽ hiện thông báo hỏi tải mô hình trực tiếp về thư mục `models/` với thanh tiến trình real-time.

### 📸 2.3. Chụp màn hình & OCR nhận diện hình ảnh (Screen Snip & Vision OCR)
- **Chụp màn hình:** Bấm vào biểu tượng Camera hoặc sử dụng phím tắt `Win + Shift + S` trên Windows để cắt vùng màn hình cần dịch.
- **Quy trình OCR đa tầng:** 
  - Hệ thống tự động phân tích ảnh và trích xuất chữ viết bằng Tesseract OCR cục bộ.
  - Khi cấu hình Vision AI, hệ thống sẽ phân tích ngữ cảnh hình ảnh để dịch chính xác các biển hiệu, truyện tranh, tài liệu chữ Hán phức tạp.

---

## ⚙️ 3. Cấu hình & Tùy biến

- **Cấu hình Model Cloud:** Bấm vào biểu tượng bánh răng Cài đặt để điền API Key (OpenAI, DeepSeek, Qwen Cloud, Gemini...) và Base URL tương ứng.
- **Tùy chọn giao diện:** Giao diện Fluent Glass hỗ trợ chế độ Dark Mode và tự động thích ứng với Windows 10 / Windows 11.

---

## ❓ 4. Xử lý sự cố thường gặp (FAQ)

1. **Không khởi động được Local AI:**
   - Đảm bảo máy tính có đủ bộ nhớ RAM trống tối thiểu 2.5 GB.
   - Kiểm tra xem file model `models/qwen2.5-1.5b-instruct-q4_k_m.gguf` đã tải hoàn tất chưa. Nếu chưa, hãy bấm tải lại từ ứng dụng.
2. **Hủy chụp màn hình bị mất cửa sổ:**
   - Lỗi này đã được khắc phục hoàn toàn ở phiên bản v1.1.0. Khi hủy chụp, ứng dụng sẽ khôi phục ngay cửa sổ và không bị ẩn khỏi taskbar.
3. **Phím tắt `Win + Shift + S` không phản hồi:**
   - Phiên bản v1.1.0 đã nhường quyền cho Windows Snipping Tool nguyên bản, bạn có thể chụp ảnh bất kỳ lúc nào và dán (Ctrl+V) hoặc chọn từ clipboard vào app.
