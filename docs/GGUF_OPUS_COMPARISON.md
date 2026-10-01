# So sánh GGUF nhúng và OPUS-MT — 2026-10-01

## Kết luận
GGUF chạy được trực tiếp trong process app, không server/HTTP. Qwen2.5-1.5B Q4_K_M đang có cải thiện một số nghĩa phụ thuộc ngữ cảnh, nhưng vẫn sai thuật ngữ và bỏ/đổi nghĩa ở mẫu sản xuất. Chưa đủ căn cứ đổi mặc định; OPUS-MT giữ mặc định, GGUF là lựa chọn thử nghiệm trong AI Studio.

Ví dụ quan sát (đầu ra nguyên bản bên dưới):
- `charge` trong tranh chấp hóa đơn: OPUS dịch “tiền phạt”; GGUF dịch “mức phí”, phù hợp hơn ngữ cảnh.
- `board` ở bài thử cold boot: OPUS dịch “hội đồng quản trị”; GGUF dịch “ngành công nghệ”. Cả hai sai nghĩa bo mạch.
- Mẫu hold/scrap: GGUF đổi “drive” thành “Đèn”, bỏ nhiều thông tin về lô hàng và điều tra; OPUS cũng dịch chưa chuẩn. Không coi văn phong trôi chảy là bản dịch đúng.
- VI→EN: cả hai giữ SN-2048 và phân biệt 15:30/13:30; GGUF đổi “bản dịch” thành “copy”, mất một phần nghĩa.

## Cách đo và giới hạn
4 đoạn giống hệt nhau, 4 threads CPU. OPUS dùng pipeline đang có (chia câu); GGUF nhận cả đoạn, chat template từ model, greedy, context 4096, giới hạn input 3072/output 1024 token. Không truyền glossary riêng cho GGUF. Load time được tách khỏi thời gian dịch; chạy tuần tự `--concurrency=1`. Một lượt smoke, không phải benchmark nhiều lượt hoặc đánh giá chất lượng blind trên corpus.

RAM là `ProcessInfo.currentRss` của toàn bộ Flutter test process tại thời điểm lấy mẫu; không phải riêng weights, không phải peak đã theo dõi liên tục. Engine chạy cùng process test nhưng unload engine trước khi sang engine tiếp theo. File JSON giữ nguyên nguồn và toàn bộ kết quả.

| Mẫu | OPUS-MT | GGUF Qwen 1.5B |
|---|---:|---:|
| invoice_charge | 0.93s | 8.75s |
| manufacturing_hold | 1.40s | 7.00s |
| cold_boot_reference | 1.46s | 7.34s |
| vi_document_integrity | 1.84s | 9.15s |

- OPUS-MT: load 0.27s; RSS sau load 216 MiB; RSS cao nhất trong các điểm sau dịch đã lấy mẫu 249 MiB.
- GGUF: load 2.92s; RSS sau load 1429 MiB; RSS cao nhất trong các điểm sau dịch đã lấy mẫu 1588 MiB.

## Nguyên văn từng mẫu

### invoice_charge (en → vi)

Nguồn:

> This is an invoice dispute, not a battery test. The customer says the charge is too high. We agreed to waive it, but the original invoice must remain in the audit log.

OPUS-MT:

> Đây là một cuộc tranh chấp hóa đơn, không phải kiểm tra pin. Khách hàng nói tiền phạt quá cao. Chúng ta đã đồng ý hủy bỏ nó, nhưng hóa đơn gốc phải ở trong nhật ký kiểm toán.

GGUF:

> Đây là một tranh chấp hóa đơn, không phải là một thử nghiệm pin. Khách hàng nói rằng mức phí quá cao. Chúng tôi đã đồng ý bỏ qua, nhưng hóa đơn gốc phải được lưu trong log kiểm tra.

### manufacturing_hold (en → vi)

Nguồn:

> The drive passed the read test, but it failed the write test. We should hold this lot, not scrap it. Here, hold means keeping the lot out of shipment while engineering investigates; it does not mean permanently rejecting it.

OPUS-MT:

> Ổ đĩa vượt qua bài kiểm tra đọc, nhưng nó đã thất bại trong bài kiểm tra viết. Chúng ta nên giữ số này, chứ không phải bỏ đi. Ở đây, giữ lại có nghĩa là giữ cho lô hàng không được đóng trong khi kỹ thuật điều tra; điều này không có nghĩa là vĩnh viễn bác bỏ.

GGUF:

> Đèn kiểm tra được, nhưng không qua kiểm tra ghi. Chúng ta nên giữ nó, không nên xả thải. "Hãy giữ" có nghĩa là giữ phần này khỏi ghi, không có nghĩa là từ bỏ nó.

### cold_boot_reference (en → vi)

Nguồn:

> The board failed the cold boot test after a power cycle. A warm restart worked, so the technician replaced the power supply. After that, the board passed the same test. Do not ship it until the final inspection is complete.

OPUS-MT:

> Hội đồng quản trị đã thất bại trong cuộc kiểm tra khởi động lạnh sau một chu kỳ năng lượng. Một khởi động lại ấm đã hoạt động, vì vậy kỹ thuật viên thay thế nguồn điện. Sau đó, hội đồng quản trị đã vượt qua bài kiểm tra tương tự. Đừng chuyển nó cho đến khi kiểm tra xong.

GGUF:

> Ngành công nghệ đã không qua được thử nghiệm cold boot sau một khởi động từ nguồn điện. Một khởi động ấm đã thành công, nên kỹ thuật viên thay thế nguồn điện. Sau đó, ngành công nghệ đã qua được thử nghiệm cùng loại. Không giao hàng cho đến khi kiểm tra cuối cùng hoàn tất.

### vi_document_integrity (vi → en)

Nguồn:

> Giữ lại lô hàng SN-2048 để kỹ sư kiểm tra lỗi ghi dữ liệu. Ổ đĩa vẫn đọc được nên chưa được kết luận là hỏng hoàn toàn. Không xóa bản ghi gốc; chỉ tạo một bản dịch để đối chiếu. Hạn xử lý là 15:30, không phải 13:30.

OPUS-MT:

> Keep the SN-2048 shipments for the engineer to check the data. The disk was still read, so it was not concluded that it was completely broken. Do not delete the original log; only create a translation for comparison. The deadline is 15:30, not 13:30.

GGUF:

> Keep the SN-2048 order safe for the engineer to check the data recording errors. The disk still reads, so it has not been concluded that it is completely broken. Do not delete the original record; only create a copy for comparison. The deadline is 3:30 PM, not 1:30 PM.

## Triển khai và kiểm chứng
- Bridge C ABI + Dart worker isolate; reuse DLL có ABI khớp headers commit 3d82ef62d47fd74e18f36c5eccbdcf965b617b17. Build script kiểm SHA-256 mọi DLL trong runtime contract. Runtime chỉ có bridge/llama/ggml/CPU/libomp, không copy server hay RPC.
- AI Studio có OPUS-MT (nhẹ) và GGUF (thử nghiệm); không tự đổi mặc định. Chọn engine sẽ unload model cũ. Startup tôn trọng lựa chọn GGUF đã lưu. Text/OCR/tài liệu dùng backend đã chọn, cache riêng gguf-native:; tài liệu chốt engine ở đầu tác vụ.
- 16 Flutter tests đạt, gồm runtime hai engine, API/cache GGUF, DOCX thật với hai engine qua endpoint cố ý hỏng, nạp/giải phóng/nạp lại, UI chọn engine và localization. 3 Python protocol tests đạt. Analyzer sạch.
- Build Debug tạo bundle riêng `.local_ai_tools/gguf-preview` vì app Debug cũ đang mở khóa kernel_blob.bin. Không dừng app. CMake cache bundle destination đã trả về mặc định sau build; Release/config.ini không thay thế.
- Preview gồm GGUF cũ và OPUS packs để so sánh nên dung lượng lớn; không phải bản phát hành tối ưu dung lượng. Chưa kiểm tra trực quan app Windows/CPU baseline cũ hoặc Release/offline deployment.
