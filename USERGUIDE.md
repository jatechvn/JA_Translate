# Hướng dẫn sử dụng JA Translate v1.2.5

Chào mừng bạn đến với **JA Translate v1.2.5** — Phần mềm dịch thuật cao cấp, tích hợp AI ngoại tuyến, nhận diện hình ảnh thông minh và công nghệ tối ưu hóa năng lượng tự động dành riêng cho hệ điều hành Windows x64.

---

## 📦 1. Cài đặt & Khởi chạy

1. Tải về file nén `JA_Translate_v1.2.5_Windows_x64.zip`.
2. Giải nén toàn bộ thư mục `JA_Translate_v1.2.5_Windows_x64` ra vị trí thuận tiện (ví dụ: `D:\Apps\JA_Translate` hoặc `C:\JA_Translate`).
3. Khởi chạy tập tin `ja_translate.exe` (hoặc chạy `debug.bat` nếu muốn xem log console).
4. *Lưu ý:* Ứng dụng chạy ở chế độ Portable độc lập, toàn bộ cấu hình và dữ liệu model được lưu ngay trong thư mục của ứng dụng mà không làm rác hệ điều hành. Ngoài ra, trong thư mục giải nén có kèm file `install.bat` và `uninstall.bat` giúp tạo/xóa shortcut Desktop & Start Menu thuận tiện mà không cần quyền Admin.

---

## 🚀 2. Các tính năng chính

### 🔄 2.1. Nút hoán đổi nhanh AI (Quick Engine Switcher)
- Trên thanh tiêu đề ứng dụng có nút Dynamic Island Capsule:
  - **Nhấp chuột 1 lần (Tap):** Đổi nhanh giữa chế độ `Local AI` (Qwen GGUF Offline) và `Cloud AI` (NVIDIA NIM Gateway / Cloud API). Thông báo Toast sẽ xuất hiện xác nhận tức thời.
  - **Nhấp giữ (Long Press):** Mở trực tiếp màn hình `AI Engine Studio` để quản lý model và xem thông số phần cứng.

### 🌐 2.2. Dịch thuật & Bảo toàn trạng thái Tab (Tab State Preservation)
- Hỗ trợ dịch đa ngôn ngữ: Tiếng Trung (Giản thể / Phồn thể), Tiếng Việt, Tiếng Anh, Tiếng Nhật, Tiếng Hàn...
- Tự động phiên âm Pinyin kèm dấu thanh điệu chuẩn cho các đoạn văn bản tiếng Hán.
- **Bảo toàn dữ liệu tuyệt đối:** Khi chuyển đổi giữa các tab (Văn bản, Tài liệu, Lịch sử, AI Studio), toàn bộ văn bản bạn đang gõ, kết quả dịch và các tùy chọn đều được giữ nguyên 100%, không bị reset.
- Tích hợp Text-to-Speech (phát âm giọng đọc bản ngữ) và Speech-to-Text (nhập liệu bằng giọng nói).

### 🤖 2.3. Chế độ AI Cục bộ Ngoại tuyến (Offline Local AI)
- Không cần kết nối Internet và không cần cài đặt Ollama phức tạp.
- Ứng dụng tích hợp sẵn backend `llama-server.exe` nội bộ và hỗ trợ mô hình tối ưu `Qwen 2.5 1.5B Instruct` (nhúng sẵn trong bản phát hành).
- Màn hình AI Studio cung cấp thông số CPU, RAM chiếm dụng và kích thước ngữ cảnh (Context Window 4,096 tokens).

### 📸 2.4. Chụp màn hình & OCR nhận diện hình ảnh (Screen Snip & Vision OCR)
- **Chụp màn hình:** Bấm vào biểu tượng Camera hoặc sử dụng phím tắt `Win + Shift + S` trên Windows để cắt vùng màn hình cần dịch.
- **Quy trình OCR đa tầng:** 
  - Hệ thống tự động phân tích ảnh và trích xuất chữ viết bằng Tesseract OCR cục bộ.
  - Khi cấu hình Vision AI, hệ thống sẽ phân tích ngữ cảnh hình ảnh để dịch chính xác các biển hiệu, truyện tranh, tài liệu chữ Hán phức tạp.

### 📋 2.5. Sao Chép Tiếng Trung Sạch Pinyin (Clean Chinese Copy)
- **Sao chép kết quả dịch:** Nút Copy ở thẻ Kết quả (Output) và màn hình Lịch sử tự động nhận diện và cắt bỏ khối phiên âm (`\n\nPinyin:\n...`), giúp bạn dán chữ Hán thuần túy vào các ứng dụng chat, tài liệu văn phòng một cách chuyên nghiệp.
- **Nút Copy trên thẻ Nhập liệu:** Thanh công cụ ô Nhập liệu được bổ sung nút Copy chuyên dụng, cho phép bạn sao chép lại đoạn văn bản nguồn một chạm (đồng thời cũng lọc bỏ Pinyin nếu văn bản nguồn có chứa phiên âm).

### 🖼️ 2.6. Dán Ảnh Trực Tiếp Từ Clipboard (Ctrl + V & Nút Paste)
- **Dán trực tiếp bằng phím tắt `Ctrl + V`:** Bạn có thể chụp ảnh màn hình bằng `Win + Shift + S` / PrtScn, sao chép ảnh trên trình duyệt web, hoặc `Ctrl + C` một file ảnh trong File Explorer rồi bấm ngay `Ctrl + V` trong ô nhập liệu (hoặc bất cứ đâu trên cửa sổ ứng dụng).
- **Tự động gắn ảnh và dịch tức thì:** Ứng dụng sẽ tự động gắn ảnh vào danh sách đính kèm bên dưới và kích hoạt ngay tiến trình OCR/Vision mà không cần mở hộp thoại duyệt file thủ công.
- **Nút Dán (Paste) thông minh:** Nút Dán trên thanh công cụ ô Nhập liệu sẽ tự động kiểm tra hình ảnh từ clipboard trước tiên; nếu có ảnh sẽ dán ảnh, nếu là văn bản sẽ dán văn bản bình thường.

### ⚡ 2.7. Tự Động Tối Ưu Năng Lượng & Giảm Tải GPU/CPU (Power Optimizer)
- **Chế độ Nhàn rỗi Thông minh (Idle Sleep > 12s):** Khi bạn không chạm chuột hoặc gõ phím quá 12 giây, ứng dụng tự động đóng băng các hoạt ảnh làm mờ nền nặng (`MeshOrb`), đưa GPU Engine về ~0.0% giúp tiết kiệm pin laptop và giảm nhiệt độ máy tính. Ngay khi bạn di chuột lại, hiệu ứng chuyển động mượt mà trở lại tức thì.
- **Tự động ngắt nhịp render khi mất focus / ẩn Tray:** Khi bạn làm việc trên các cửa sổ khác hoặc thu nhỏ/ẩn ứng dụng vào khay hệ thống (System Tray), toàn bộ nhịp vẽ GPU được ngắt hoàn toàn.
- **Bảo toàn tác vụ nền:** Các tiến trình dịch AI cục bộ, lắng nghe Clipboard và phím tắt toàn cầu (`Alt+Q`, `Alt+S`) tiếp tục hoạt động liên tục mà không bị gián đoạn.

### 🛡️ 2.8. Quản Lý Đóng Cửa Sổ & Khay Hệ Thống (Window Close & System Tray)
- **Thoát sạch mặc định:** Khi bạn bấm nút **[X]** trên thanh tiêu đề, ứng dụng sẽ tự động dọn dẹp tiến trình con (`llama-server.exe`) và thoát hoàn toàn khỏi hệ điều hành, không để lại tiến trình ma trong Windows Task Manager.
- **Tùy chọn chạy ngầm linh hoạt:** Nếu bạn muốn giữ app luôn sẵn sàng để bấm phím tắt toàn cục `Alt + Q` (Mở nhanh) hoặc `Alt + S` (Chụp màn hình dịch), bạn chỉ cần vào **Cài đặt Chung** và bật tùy chọn *"Thu nhỏ vào khay hệ thống khi đóng"*. Khi đó, bấm nút [X] sẽ thu nhỏ ứng dụng xuống khay Taskbar.
- **Thoát dứt điểm từ Tray:** Khi app đang ở khay Taskbar, chỉ cần nhấp chuột phải vào biểu tượng khay và chọn **Exit** để thoát hoàn toàn mọi tiến trình.

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
