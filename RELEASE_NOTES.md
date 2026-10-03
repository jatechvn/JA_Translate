TAG=v1.2.3
TITLE=JA Translate v1.2.3 — Chuẩn Hóa Tiêu Đề Cửa Sổ & Windows Metadata (App Name Alignment)
BODY=
## JA Translate v1.2.3 — Chuẩn Hóa Tiêu Đề Cửa Sổ & Windows Metadata (App Name Alignment)

- **Chuẩn hóa Tiêu đề Cửa sổ Native:** Khởi tạo cửa sổ trong `windows/runner/main.cpp` với tiêu đề `JA Translate` thay vì tên tệp nhị phân `ja_translate`. Đảm bảo thanh tác vụ Windows (Taskbar) và cửa sổ `Alt + Tab` luôn hiển thị tiêu đề đẹp mắt `JA Translate  v1.2.3`.
- **Đồng bộ Thông tin Định danh PE Metadata (`Runner.rc`):**
  - Cập nhật `FileDescription` và `ProductName` thành `JA Translate`: Windows Task Manager hiển thị rõ ràng tên ứng dụng "JA Translate" trong danh sách tiến trình thay vì tên file `ja_translate`.
  - Cập nhật `CompanyName` và `LegalCopyright` thành `JA-Tech System`.
- **Kiểm thử tự động toàn diện:** 45/45 tests passed 100%, static analysis không lỗi (`No issues found!`).

### Cài đặt
Giải nén toàn bộ `JA_Translate_v1.2.3_Windows_x64.zip` và chạy `ja_translate.exe`. Xem `USERGUIDE.md` trong gói để biết thêm chi tiết.
