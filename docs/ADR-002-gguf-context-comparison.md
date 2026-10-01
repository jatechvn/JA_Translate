# ADR-002: GGUF nhúng để thử khả năng hiểu ngữ cảnh

**Status:** Accepted — backend thử nghiệm; chưa đổi mặc định
**Date:** 2026-10-01
**Deciders:** Johnny yêu cầu thử GGUF hiện có và so sánh cùng đoạn văn

## Context
OPUS-MT ưu tiên dung lượng, chia câu và yếu về liên kết ngữ cảnh. Người dùng đồng ý thử Qwen2.5-1.5B-Instruct Q4_K_M hiện có qua engine nhúng trước khi quyết định engine mặc định.

## Decision
Thêm backend `gguf_native` qua C ABI bridge + Dart worker isolate. Engine dùng chính llama/ggml DLL hiện có nhưng không chạy executable/server/HTTP. Headers phải khớp commit 3d82ef62d47fd74e18f36c5eccbdcf965b617b17; kiểm hashes mọi DLL bằng runtime_contract.json. Copy CPU x64 + AVX2 fallback và libomp, không copy server/RPC/common/CLI/vision.

GGUF nhận cả đoạn (context 4096; input tối đa 3072, output tối đa 1024), chat template từ model, greedy. Không trả phần dịch thiếu khi chạm giới hạn. AI Studio cho chọn thử GGUF hoặc OPUS; giữ OPUS mặc định và tôn trọng lựa chọn người dùng đã lưu. Đổi engine giải phóng model của cả hai worker trước khi ghi cấu hình.

## Options Considered
- Reuse verified CPU DLL + matching headers: compile bridge nhỏ, tận dụng runtime hiện có; cần kiểm ABI/hash nghiêm ngặt. Đã chọn cho thử nghiệm này.
- Build llama.cpp mới: tự chủ build nhưng không cần cho so sánh model hiện có, phát sinh backend/version/compatibility mới. Chưa triển khai.
- Quay lại llama-server: không đáp ứng yêu cầu inference trong app.

## Trade-off Analysis
Đọc GGUF_OPUS_COMPARISON.md/.json. Trên bốn mẫu, GGUF chọn đúng nghĩa “phí” ở hóa đơn nhưng vẫn sai drive/board và bỏ nghĩa ở bài sản xuất. Dung lượng GGUF khoảng 1.04 GiB, RSS process khi lấy mẫu khoảng 1.6 GiB; OPUS nhỏ và nhanh hơn nhưng cũng sai thuật ngữ. Không lấy văn phong làm bằng chứng đúng nghĩa. Chưa đủ căn cứ đổi mặc định.

## Consequences
- Có thể thử model theo đoạn ngay trong app; không cần server/port hay process AI.
- RAM và thời gian tăng; lỗi native có thể ảnh hưởng process app. Kết quả hiện tại dành cho model 1.5B cụ thể, không suy rộng sang mọi LLM.
- Text/OCR/PDF/Office delegate engine đã chọn. Giữ cache gguf-native: riêng; engine tài liệu chốt ở đầu tác vụ.
- Bản preview thử nghiệm chứa cả OPUS và GGUF để so sánh; không phải package tối ưu dung lượng. Release hiện có giữ nguyên.
- Ngưỡng context hữu hạn, chưa làm streaming token/cancel mid-generation; UI nhận nguyên đoạn sau khi decode xong.

## Action Items
- [x] Prototype FFI trên model thật, unload/reload.
- [x] So sánh nguyên văn bốn mẫu, ghi thời gian/RSS.
- [x] Text/cache/DOCX native và UI selector/localization.
- [x] Build preview riêng vì Debug đang chạy khóa kernel_blob.bin.
- [ ] Người dùng xem bản dịch và lựa chọn model/engine tiếp theo; không tự tải model khác hoặc đổi mặc định.

## Quyết định cập nhật — 2026-10-01
Johnny chọn dùng lại Qwen thay OPUS. GGUF native trở thành mặc định Local; dữ liệu so sánh chất lượng giữ nguyên. Không tải thêm model hoặc thay model đang có.
