"""Fix MSVC DLL thread-local pool teardown before thread detach/loader lock."""
from pathlib import Path
root = Path(__file__).resolve().parent.parent / '.local_ai_tools/CTranslate2'
patches = {
 'src/cpu/parallel.cc': [
 ('    BS::thread_pool_light& get_thread_pool() {\n      static thread_local BS::thread_pool_light thread_pool(num_threads);\n      return thread_pool;\n    }',
 '    static thread_local std::unique_ptr<BS::thread_pool_light> thread_pool;\n    BS::thread_pool_light& get_thread_pool() {\n      if (!thread_pool) thread_pool = std::make_unique<BS::thread_pool_light>(num_threads);\n      return *thread_pool;\n    }\n    void release_thread_pool() { thread_pool.reset(); }')],
 'src/cpu/parallel.h': [('    BS::thread_pool_light& get_thread_pool();', '    BS::thread_pool_light& get_thread_pool();\n    void release_thread_pool();')],
 'src/cpu/backend.cc': [
 ('    ruy::Context *get_ruy_context() {\n      static thread_local ruy::Context context;\n      return &context;\n    }',
 '    static thread_local std::unique_ptr<ruy::Context> context;\n    ruy::Context *get_ruy_context() {\n      if (!context) context = std::make_unique<ruy::Context>();\n      return context.get();\n    }\n    void release_ruy_context() { context.reset(); }')],
 'src/cpu/backend.h': [('    ruy::Context *get_ruy_context();','    ruy::Context *get_ruy_context();\n    void release_ruy_context();')],
 'src/thread_pool.cc': [
 ('#include "ctranslate2/utils.h"','#include "ctranslate2/utils.h"\n#include "cpu/parallel.h"\n#include "cpu/backend.h"'),
 ('    finalize();\n    local_worker = nullptr;', '    finalize();\n#ifndef _OPENMP\n    cpu::release_thread_pool();\n#endif\n#ifdef CT2_WITH_RUY\n    cpu::release_ruy_context();\n#endif\n    local_worker = nullptr;')],
}
for name, replacements in patches.items():
 path=root/name; text=path.read_text(encoding='utf-8'); original=text
 for before, after in replacements:
  if after in text: continue
  if before not in text: raise RuntimeError(f'Pinned source mismatch: {name}')
  text=text.replace(before,after)
 if text != original: path.write_text(text,encoding='utf-8')
print('Windows thread teardown patch applied')
