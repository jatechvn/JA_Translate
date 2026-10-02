# AI handoff — 2026-10-01

## Phạm vi vừa hoàn tất
- GGUF download thuộc ModelDownloadController.instance, không phụ thuộc vòng đời AI Studio. View gắn/bỏ listener; quay lại đọc tiến trình hiện tại. Chặn tác vụ trùng, hiển thị bytes đã tải/tổng bytes và tốc độ theo từng cập nhật.
- EngineReadiness kiểm tra engine đang chọn: Cloud cần API key/model/API URL; Local cần đúng gguf_model đã cài và llama-server. UI hiển thị Đã cấu hình thay vì mặc định READY; không chứng minh kết nối dịch thật.
- Local model selection đồng bộ model và gguf_model. Cloud fallback dùng setActiveProvider.
- Hộp thoại thiếu cấu hình hỗ trợ VI/ENG/CN. Nhãn nút dịch co vừa không gian ở cửa sổ nhỏ.

## Kiểm chứng
- dart analyze toàn dự án: No issues found.
- 8 test đạt trong model_download_controller_test, engine_readiness_test, ai_studio_language_test, text_engine_status_widget_test và widget_test.
- Dùng dart SDK trực tiếp và flutter_tools.dart do Flutter wrapper/SDK lockfile trong sandbox.
- Chưa kiểm tra tải model thực qua mạng, native Windows UI, dịch Local/Cloud thật hoặc build release.

## Lưu ý tiếp tục
- Worktree có nhiều thay đổi có sẵn; chưa commit, build hoặc thay thế artifacts.
- Transfer tests dùng stream giả; widget test kiểm tra trạng thái Cloud và hộp thoại theo ngôn ngữ, không phải native UI.


## Sửa hồi quy sau phản hồi của Johnny
- Thanh bị đục là title/tab của JA Translate, không phải Windows taskbar.
- Native runner là nơi quản lý composition: ThemeProvider không gọi plugin ghi đè sau native sync thành công. Win11 tái áp frame, client Acrylic và title-bar backdrop trên mỗi lần đổi theme; giữ tint alpha 0x1F như Dart fallback.
- Models/server executable được resolve tuyệt đối trước khi chạy process với workingDirectory=bin. AI Studio dùng llama_port/threads từ config, hiển thị lỗi start và chọn active_provider=local khi start thành công. Cho phép model lớn nạp lâu hơn 10 giây.
- Khi có GGUF nhưng Cloud chưa có API key: reconcile model và chọn Local lúc startup, vào AI Studio hoặc tải model thành công. Giữ Cloud khi đã có key. AppConfig.changes giúp DashboardShell cập nhật sau thay đổi cấu hình.
- Kiểm chứng cuối: dart analyze sạch; 11 test đạt; build windows --debug thành công. Release chưa được thay thế.
- Kiểm chứng runtime trực tiếp với bin/llama-server.exe + model thật trên port 18081: health ok, chat trả OK; dừng đúng PID thử nghiệm. Đây là kiểm tra executable/model bằng đường dẫn tuyệt đối, chưa phải click nút trong app.
- Native title/tab vẫn cần kiểm tra trực quan bằng app Windows. Không khẳng định build hoặc channel mock chứng minh hiệu ứng trong suốt thực tế.


## Kiểm tra lịch sử và phương án embedded AI
- Xác minh tất cả refs local: chỉ có 5ec448b (Cloud HTTP) và 67356f9 (Local qua llama-server + localhost HTTP). Chưa có inference in-process trong lịch sử hiện có.
- docs/ADR-001-embedded-local-ai.md: đề xuất GGUF + native llama.cpp C ABI qua dart:ffi worker isolate; không thêm Rust/server.
- PDF/Word/Excel/PowerPoint vẫn có phụ thuộc HTTP ở Python, cần chuyển inference tài liệu cùng backend mới.
- Đã hỏi Johnny lựa chọn giữ GGUF hay model dịch chuyên dụng; chưa sửa runtime backend vì lựa chọn này ảnh hưởng model compatibility và hành vi.


## Embedded translation hoàn tất — lựa chọn ưu tiên dung lượng
- Johnny chọn model dịch chuyên dụng. ADR-001 Accepted; hướng dẫn tái tạo: docs/LOCAL_TRANSLATION.md.
- OPUS-MT INT8, 4 gói en-vi/vi-en/en-zh/zh-en khoảng 302.8 MiB. VI ↔ ZH pivot EN. Gói zh-vi đã thử vẫn được giữ trong workspace/build cũ, không thuộc danh sách runtime và không cài vào build mới. Không xóa artifact.
- CPU native CTranslate2 v4.6.0 + Ruy, SentencePiece v0.2.1 + C ABI bridge, hai DLL khoảng 7.1 MiB. Không CUDA/MKL/server/HTTP/process AI. Python/PyTorch chuyển đổi chỉ ở .local_ai_tools; không đóng gói. Python Office/PDF giữ nhiệm vụ định dạng.
- Native worker isolate thuộc singleton service, sống độc lập view/tab; một model hoạt động. UI nạp/giải phóng, tự nạp theo cặp dịch, hiển thị kích thước và localization VI/ENG/CN; Dashboard theo dõi native lifecycle.
- ApiClient text/TXT/OCR dùng FFI, giữ cache namespace opus: tách khỏi GGUF/Cloud. Document helper --app-translation gọi app qua serialized stdin/stdout UTF-8, không HTTP; bỏ chọn stale Cython helper cho native. Explicit cache path được tôn trọng.
- Startup chọn opus_mt khi có DLL+gói; chọn Local nếu Cloud chưa có key, giữ Cloud đã cấu hình. Không sửa config.ini trong khi test.
- Sửa các lỗi phát hiện bằng runtime: MSVC DLL thread-local pool teardown treo unload (patch pinned CT2); Marian EOS và language prefix; đoạn nhiều câu lặp bị bỏ phần cuối (chia câu trước token split).
- Native CMake cài DLL/licenses và 4 gói; package_dist không bổ sung bin/GGUF cho native. Không chạy package_dist, không thay Release, không commit/push.

### Kiểm chứng cuối
- dart format các Dart thay đổi; dart analyze: No issues found.
- 15 Flutter tests đạt: native DLL thật cho 6 chiều, VI/ZH pivot, unload/reload, giữ newline, đoạn dài giữ số ở câu cuối; DOCX thật dùng endpoint cố ý không hoạt động; embedded Studio widget + đổi ngôn ngữ; các hồi quy download/config/theme-channel/text UI.
- 3 Python protocol tests đạt; Python AST syntax checks đạt cho converter/patch/helper.
- scripts/build_local_translation.ps1 chạy thành công với pinned source và patch. CMake build native Release DLL thành công; Flutter build windows --debug cuối thành công.
- Native engine/packs đã có trong build/windows/x64/runner/Debug. Build cũ có thể còn extra zh-vi và files legacy vì không cleanup.
- Chưa kiểm tra trực quan transparency title/tab Windows, click app Windows, packaged/offline deployment hay Release. Widget QA không chứng minh Acrylic. Chưa thực nghiệm PDF/XLSX/PPTX layout hoặc OCR với ảnh thật.
- Smoke câu ngắn/DOCX không chứng minh chất lượng toàn bộ tài liệu; pivot EN và tự nhận diện nguồn theo ký tự có giới hạn. Tiếng Việt không dấu nên chọn nguồn thủ công.

## GGUF thử nghiệm — 2026-10-01
- Thêm lib/modules/gguf_translation_service.dart và native/gguf_translation/bridge.cpp; C ABI gọi llama/ggml DLL cùng ABI commit 3d82ef62d47fd74e18f36c5eccbdcf965b617b17. SHA của 6 DLL trong runtime_contract.json; build script từ chối mismatched runtime. CPU x64 + AVX2/libomp; không server/RPC/CLI.
- AI Studio thêm selector OPUS/GGUF thử nghiệm, nạp/giải phóng. Main/reconcile/EngineReadiness/Dashboard tôn trọng và theo dõi engine mới. Text/OCR/tài liệu routing GGUF native; cache gguf-native: tách OPUS/legacy. Document chốt engine ở đầu request.
- Không đổi mặc định hay config.ini. GGUF nhận nguyên đoạn để dùng ngữ cảnh; context4096/input<=3072/output<=1024, greedy. Không streaming token/cancel mid-generation. Quá context/output báo lỗi thay vì trả đoạn thiếu.
- docs/GGUF_OPUS_COMPARISON.json và .md giữ nguyên 4 nguồn + đầu ra + thời gian/RSS. GGUF đúng charge=mức phí hơn OPUS=tiền phạt, nhưng drive/board và mẫu hold/scrap vẫn sai nặng; chưa đủ căn cứ chuyển mặc định. Mean ratio lượt cuối khoảng5.7 lần; RSS là whole test process sampled, không phải isolated/peak RAM model.
- Kiểm chứng: 16 test Flutter full suite đạt gồm native comparison, API/cache GGUF, DOCX thật cả hai engine qua endpoint cố ý hỏng, native UI selector/localization và hồi quy. 3 Python protocol tests đạt; analyzer sạch. Thêm focused regression startup giữ lựa chọn GGUF (xem log .local_ai_tools).
- Bridge Release build thành công. Debug cũ đang chạy PID80328 khóa kernel_blob.bin nên install vào bundle cũ thất bại. Không dừng app. Thêm optional JA_BUNDLE_DIR, build thành công vào .local_ai_tools/gguf-preview; đã xác minh exe/kernel/native DLL/GGUF1,117,320,736 bytes ở preview. CMake cache JA_BUNDLE_DIR đã trả rỗng sau build. Preview chưa launch/click native Windows; test widget không chứng minh Acrylic.
- Không commit/push/package_dist/Release overwrite; source GGUF/bin/caches giữ nguyên. User cần mở preview riêng để chạy mã mới; app Debug đang mở vẫn là bản cũ.
- ADR-002 Accepted cho backend thử nghiệm, chưa chọn GGUF mặc định. Cần model tốt hơn nếu muốn cải thiện chất lượng; không tự tải model khác.

## Qwen mặc định theo yêu cầu — 2026-10-01
- User chọn dùng các Qwen cũ thay OPUS. AppConfig default gguf_native; reconcile dùng marker qwen_native_migration=1 chuyển legacy/OPUS một lần. Giữ Cloud đã cấu hình; Local có model và Cloud thiếu key thì ưu tiên Local.
- AI Studio thay selector OPUS/thử nghiệm bằng model Qwen đã cài, unload trước khi đổi model và đồng bộ model/gguf_model. Hiện chỉ có qwen2.5-1.5b-instruct-q4_k_m.gguf 1,117,320,736 bytes; chưa tải thêm. Xóa nhãn thử nghiệm/lời mô tả không đổi mặc định VI/ENG/CN.
- Cache GGUF chứa tên/path model; document IPC prefix tương ứng; API không ghi cache vào model mới nếu lựa chọn đổi giữa request.
- CMake chỉ thêm native/gguf và qwen*.gguf vào bundle mới (Debug và Release); không kèm OPUS/server. package_dist điều kiện dùng runtime GGUF; chưa thực thi packaging. OPUS/source/models cũ giữ nguyên.
- Format đạt, analyze sạch, 11 Flutter hồi quy đạt (startup migration/Cloud/UI/localization/readiness), 3 Python protocol đạt. Native DOCX test đạt cho cả hai backend qua endpoint Cloud cố ý hỏng. Kiểm tra Python ban đầu dùng unittest module path không hợp lệ; chạy file entrypoint lại đạt.
- Preview riêng .local_ai_tools/qwen-default-preview. Chưa launch/click Windows, chưa chứng minh transparency native hay chất lượng tổng quát; số liệu so sánh trước đó giữ nguyên. Không commit/push/ghi đè Release hay config.ini người dùng.
- Flutter build windows --debug thành công vào preview riêng; đã xác minh EXE, native/gguf và model đúng kích thước. Đã trả JA_BUNDLE_DIR trong CMake cache về rỗng.

## Ảnh vẫn OPUS — 2026-10-01
- Xác minh PID80328 dùng build/windows/x64/runner/Debug, kernel10:39; preview Qwen kernel11:31. Mutex Local/ja_translate_single_instance_mutex khiến mở preview khi app cũ còn chạy chỉ focus OPUS.
- Trong lượt này user đã chuyển sang preview Qwen PID80852; preview/config.ini engine=gguf_native, qwen_native_migration=1. Không dừng tiến trình hay sửa config gốc.
- Sửa nhãn Local AI (llama-server) thành Local AI (Qwen) VI/ENG/CN. Format/analyzer sạch, 3 tests UI/ngôn ngữ đạt. Build nhãn vào preview cũ bị khóa vì user đã mở; xuất riêng qwen-label-preview. Chưa click/QA Windows trực quan.
- Build preview sửa nhãn thành công; CMake JA_BUNDLE_DIR đã trả rỗng.

## Verify báo cáo đa ngôn ngữ — 2026-10-02
- Read-only review diff và report đính kèm; không sửa implementation. Analyzer sạch; toàn bộ flutter test: 33 passed, 3 skipped (native runtime/DOCX/comparison cần env flags). Log .local_ai_tools/localization-verification.log.
- P2: dashboard_shell.dart:104-111,353-358 so code vi/zh thay VI/CN, toast/tooltip rơi ENG; các key topbar_switch/switched trong từ điển chưa được dùng tại đó.
- P2: document_translation_view.dart:125-126 xóa status key và hiển thị p.status thô; translator reading_file/translating_chunk và Python status ENG chưa được bản địa hóa.
- Coverage: complete_localization_test.dart:96-104 gọi t() có fallback ENG/VI, nên thiếu bản CN vẫn có thể pass. Chưa test UI các nhánh TopBar/progress hoặc QA native Windows. Báo cáo hoàn tất toàn diện chưa được chứng minh.

## Sửa hồi quy đa ngôn ngữ — 2026-10-02
- dashboard_shell.dart: toast và tooltip chuyển Local/Cloud dùng key dictionary thay so mã vi/zh sai.
- language_provider.dart: documentProgressText map status Dart/Python hiện có sang key bản địa hóa, giữ counts; unknown status dùng doc_translating. View lưu raw status và counts, render theo locale hiện tại nên đổi ngôn ngữ cập nhật tiến độ.
- Thêm 9 key VI/ENG/CN, hasTranslation kiểm tra locale trực tiếp không fallback. complete_localization_test kiểm tra entries thật bao gồm key mới. localization_regression_test kiểm tra mọi stage/format/cached/count/error và bấm chuyển cả hai engine tại VI/ENG/CN.
- Format/analyzer sạch; 6 related tests đạt; kiểm tra dictionary sau mở rộng keys đạt 2/2. Fixture test TopBar ban đầu bị startup migration chọn Local; đã chờ init và thiết lập Cloud trước từng locale, rerun đạt.
- Flutter Debug build thành công, artifact đã xác minh tại .local_ai_tools/localization-fix-preview. Không dừng app hay ghi đè Release; CMake JA_BUNDLE_DIR trả rỗng. Chưa native Windows visual QA/PDF thực nghiệm ở bản mới; widget và formatter checks đạt.
