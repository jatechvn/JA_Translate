TAG=v1.2.5
TITLE=JA Translate v1.2.5 — Sao Chép Tiếng Trung Sạch Pinyin & Dán Ảnh Trực Tiếp Từ Clipboard
BODY=
## JA Translate v1.2.5 — Sao Chép Tiếng Trung Sạch Pinyin & Dán Ảnh Trực Tiếp Từ Clipboard

- **Sao Chép Chữ Hán Thuần Túy Không Kèm Pinyin:**
  - Nút Copy ở thẻ Kết quả (Output) tự động loại bỏ phần chú thích phiên âm (`\n\nPinyin:\n...`), chỉ sao chép chữ Hán gốc sang clipboard.
  - Bổ sung nút Copy chuyên dụng trên thanh công cụ của thẻ Nhập liệu (Input), hỗ trợ sao chép nhanh văn bản nguồn và lọc sạch Pinyin.
  - Đồng bộ bộ lọc Pinyin sang màn hình Lịch sử dịch thuật và Cửa sổ chính.
- **Dán Ảnh Trực Tiếp Từ Clipboard (`Ctrl + V` & Nút Paste):**
  - Hỗ trợ dán ảnh bằng phím tắt `Ctrl + V` trực tiếp ngay trong ô văn bản nhập liệu hoặc ngoài cửa sổ: tự động nhận diện ảnh chụp màn hình (`Win + Shift + S`, PrtScn), ảnh copy từ trình duyệt web hoặc tệp ảnh copy từ Windows Explorer (`CF_HDROP`).
  - Tự động gắn ảnh vào danh sách đính kèm (`_attachedImages`), hiển thị thông báo Toast nổi và tự động kích hoạt tiến trình OCR/Vision.
  - Nâng cấp nút Dán (Paste) trên thanh công cụ Input: ưu tiên dán ảnh từ clipboard trước khi đọc văn bản thông thường.
  - Bản địa hóa thông báo `toast_image_pasted` cho cả 3 ngôn ngữ: VI, ENG, CN.
- **Kiểm Thử Toàn Diện:**
  - Bổ sung `test/chinese_clean_copy_test.dart` (6 bài test kiểm chứng cắt lọc Pinyin).
  - Toàn bộ **53/53 bài kiểm thử** tự động đều vượt qua 100%, `flutter analyze` 0 warnings.

### Cài đặt
Giải nén toàn bộ `JA_Translate_v1.2.5_Windows_x64.zip` và chạy `ja_translate.exe`. Xem `USERGUIDE.md` trong gói để biết thêm chi tiết.
