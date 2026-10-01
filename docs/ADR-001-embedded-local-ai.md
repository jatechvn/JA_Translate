# ADR-001: Dịch Local trực tiếp trong JA Translate

**Status:** Accepted (2026-10-01, Johnny chọn model dịch chuyên dụng, ưu tiên dung lượng)

## Context
Lịch sử local chỉ có 5ec448b (Cloud HTTP) và 67356f9 (llama-server + localhost HTTP). Không có engine in-process trong hai commit này. GGUF hiện có chiếm 1,117,320,736 bytes; đổi cách gọi riêng không làm weights nhỏ đi.

## Decision
Dùng OPUS-MT INT8 với CTranslate2 4.6.0, Ruy CPU và SentencePiece 0.2.1. Bridge C ABI được gọi qua Dart FFI trong worker isolate sống độc lập với các tab. Không dùng AI server, cổng HTTP local, process AI phụ, CUDA hay MKL.

Bốn gói cơ bản: en-vi, vi-en, en-zh, zh-en, tổng khoảng 303 MiB. VI ↔ ZH đi qua EN để tránh thêm gói dịch. Một thời điểm chỉ nạp một model. Hai DLL tổng khoảng 7.1 MiB; số này không bao gồm Flutter, tài liệu/OCR và MSVC runtime.

Python/PyTorch chỉ dùng chuyển model lúc chuẩn bị build. Python xử lý PDF/Office hiện có được giữ; requests dịch ở chế độ native đi qua stdin/stdout về engine trong app, không gọi HTTP. Text/TXT dùng engine trực tiếp.

## Alternatives
- GGUF + llama.cpp FFI: bỏ server nhưng vẫn phải giữ weights khoảng 1.1 GB. Không chọn vì ưu tiên dung lượng.
- Năm gói với zh-vi trực tiếp: đã chuyển thử, nhưng thêm khoảng 79 MiB. Không đưa vào cấu hình tối thiểu.
- Giữ llama-server: giữ làm tương thích với dữ liệu cũ, không dùng cho backend OPUS-MT.

## Consequences
- AI Studio dùng nạp model/giải phóng RAM, liệt kê kích thước từng gói; không có cấu hình port cho backend mới.
- Đổi tab không sở hữu hay hủy worker native. Dịch trả kết quả theo đoạn; không phải token streaming của LLM.
- Marian converted bằng Transformers cần EOS và language prefix: en-vi >>vie<<, en-zh >>cmn_Hans<<.
- Đoạn dài được chia theo số token; giới hạn decoder vẫn có thể ảnh hưởng bản dịch có độ giãn nở lớn. Không coi mẫu smoke là chứng minh chất lượng mọi tài liệu.
- Tự phát hiện nguồn dựa trên ký tự; tiếng Việt không dấu nên chọn nguồn thủ công. Model chuyên dụng không làm chat/instruction/vision; ảnh dùng OCR rồi dịch text.
- Có patch pinned CTranslate2 giải phóng thread-local CPU pools trước Windows DLL thread detach. Không áp patch vào nguồn khác phiên bản.
- Native crash có thể ảnh hưởng app process; không có cách ly kiểu server.
- Không xóa GGUF, bin, cache/config hay Release cũ. Thư mục build có thể còn gói zh-vi từ thử nghiệm; CMake chỉ cài bốn gói vào build mới, không xóa artifact tồn tại.

## Verification
Đọc docs/AI_HANDOFF.md cho kết quả kiểm chứng hiện tại và giới hạn visual/packaging.

## Primary references
- https://opennmt.net/CTranslate2/guides/opus_mt.html
- https://opennmt.net/CTranslate2/quantization.html
- https://huggingface.co/Helsinki-NLP/opus-mt-en-vi
- https://huggingface.co/Helsinki-NLP/opus-mt-en-zh
