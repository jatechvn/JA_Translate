# Local Qwen mặc định — 2026-10-01

Theo lựa chọn của Johnny, Local dùng `gguf_native` và Qwen2.5 1.5B Q4_K_M hiện có (1,117,320,736 bytes). Engine gọi llama/ggml DLL trong tiến trình app, không chạy llama-server hay HTTP. AI Studio chọn các file qwen*.gguf đã cài; chưa tải thêm model. Cache tách theo model.

Startup chuyển cấu hình OPUS/legacy sang Qwen một lần (`qwen_native_migration=1`); Cloud đã cấu hình vẫn giữ lựa chọn. Bundle Windows mới chỉ thêm runtime GGUF và các Qwen hiện có; file OPUS trong workspace được giữ lại. Build bridge bằng `scripts/build_gguf_bridge.ps1`. Chất lượng đo trước đó trong GGUF_OPUS_COMPARISON.md vẫn có giới hạn, không tuyên bố Qwen 1.5B tốt hơn ở mọi mẫu.

## Tài liệu OPUS trước đây (backend tùy chọn)

# Embedded Local Translation

Local OPUS-MT runs in the app through `native/local_translation/bridge.cpp` and `lib/modules/local_translation_service.dart`. The CPU library and models are generated artifacts, ignored by Git. Model packs are separate so installations can omit unused language pairs; missing routes show configuration-required status.

## Prepare native libraries (Windows x64)
Requires Visual Studio C++ Build Tools, CMake, Git, and Python only on the build machine. Keep `.local_ai_tools` outside the distributed bundle.

```powershell
python -m venv .local_ai_tools/venv
./.local_ai_tools/venv/Scripts/python.exe -m pip install 'setuptools==80.9.0' 'ctranslate2==4.6.0' 'sentencepiece==0.2.1' 'transformers==4.55.4' 'sacremoses==0.1.1'
./.local_ai_tools/venv/Scripts/python.exe -m pip install 'torch==2.8.0+cpu' --index-url https://download.pytorch.org/whl/cpu
./scripts/build_local_translation.ps1 -CMake 'cmake'
./.local_ai_tools/venv/Scripts/python.exe -X utf8 scripts/prepare_opus_models.py en-vi vi-en en-zh zh-en
```

Use an absolute CMake executable if it is not on PATH. Build script pins upstream source revisions, applies the MSVC teardown patch, builds CPU-only DLLs, and copies engine/transitive license notices. Conversion pins model repository SHA in `source_revision.txt`; manifests record source provenance, file hashes, quantization and required language prefix. Model cards travel with packs. OPUS model licenses: Apache-2.0.

Source downloads/PyTorch are much larger than the resulting INT8 packs and are not shipped. Do not remove a partial destination or runtime data automatically; the preparation script preserves existing model packs and reports incomplete destinations.

## App/runtime layout
```
ja_translate.exe
native/ja_translation.dll
native/ctranslate2.dll
native/licenses/*
models/opus-mt/en-vi/*
models/opus-mt/vi-en/*
models/opus-mt/en-zh/*
models/opus-mt/zh-en/*
```

Windows CMake installs generated runtime and the four packs beside the executable. Debug development also falls back to workspace paths. When native runtime + a pack are present, startup selects `LOCAL_AI.engine=opus_mt`; if Cloud has no key, it selects Local. An already configured Cloud remains selected.

A fresh native package does not copy legacy `bin` or GGUF weights. `package_dist.ps1` was not executed in this task; its pre-existing replacement/cleanup behavior requires a separate release workflow. Existing build directories and Release remain preserved.

Text/Markdown/OCR text uses native translation directly. PDF/Office retains its Python formatting helper, with `--app-translation` delegating translation to app FFI via a serialized request/reply channel. It uses UTF-8 and a separate `opus:` cache namespace. This is not a Python AI runtime.

## Verification
```powershell
$env:JA_TEST_NATIVE = '1'
flutter test test/local_translation_runtime_test.dart test/native_document_runtime_test.dart
python -X utf8 test/document_native_protocol_test.py
```

Native tests are opt-in because they require generated DLLs/model packs. DOCX smoke requires the existing document Python dependencies and currently uses Python313 on Windows; it retains isolated fixture artifacts under `.local_ai_tools`. Normal tests do not download models. Native title/tab transparency and real PDF/XLSX/PPTX layout must be validated separately. VI/ZH pivots and automatic source detection have quality limits documented in ADR-001.

## GGUF comparison backend

`gguf_native` is an opt-in experimental engine in AI Studio; OPUS remains the startup default unless the user explicitly selects GGUF. See ADR-002 and GGUF_OPUS_COMPARISON.md/.json for exact passages, output and limitations.

The bridge reuses verified CPU DLLs from `bin/` without launching any executable. Header ABI is pinned to commit `3d82ef62d47fd74e18f36c5eccbdcf965b617b17`; `native/gguf_translation/runtime_contract.json` pins all reused DLL hashes. Do not update binary/header versions independently.

```powershell
git clone --no-checkout https://github.com/ggml-org/llama.cpp.git .local_ai_tools/llama.cpp
git -C .local_ai_tools/llama.cpp config core.longpaths true
git -C .local_ai_tools/llama.cpp fetch --depth 1 origin 3d82ef62d47fd74e18f36c5eccbdcf965b617b17
git -C .local_ai_tools/llama.cpp checkout --detach FETCH_HEAD
./scripts/build_gguf_bridge.ps1 -CMake 'cmake'
$env:JA_COMPARE_NATIVE = '1'
flutter test test/gguf_opus_comparison_test.dart --concurrency=1
```

Existing clone: skip the clone step. Build script also requires MSVC dumpbin/lib tools (override MsvcBin if installed elsewhere). It copies only bridge, llama/ggml, CPU x64+AVX2 and OpenMP plus license notices into `native/runtime/gguf`.

The worker translates a complete passage, maximum 3072 input tokens within a 4096-token context and 1024 generated tokens. Limit failure returns an error, not a partial translation. It currently emits the completed passage rather than live tokens and does not interrupt a generation mid-call. It survives tab changes. Model quality is not guaranteed by successful execution.

Windows Debug installs the existing Qwen GGUF beside the app for comparisons; Release does not automatically copy this large model. A GGUF-only Release needs an explicitly prepared model path before distribution; no Release/package was produced here.

If an existing Debug app locks kernel_blob.bin, configure an isolated bundle destination with CMake's optional `JA_BUNDLE_DIR`, then build Debug; restore that CMake cache value to empty afterward. This task's completed preview is `.local_ai_tools/gguf-preview/ja_translate.exe`, while the old Debug app remained running.
