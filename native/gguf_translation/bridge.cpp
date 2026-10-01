#include <llama.h>
#include <ggml-backend.h>
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <vector>
#define JA_API extern "C" __declspec(dllexport)
namespace {
thread_local std::string error;
std::once_flag initialized;
struct Engine {
  llama_model* model = nullptr;
  llama_context* context = nullptr;
  ~Engine() { if (context) llama_free(context); if (model) llama_model_free(model); }
};
void quiet(enum ggml_log_level, const char*, void*) {}
std::string language(const char* code) {
  std::string value(code);
  if (value == "vi" || value == "VI" || value == "VN") return "Vietnamese";
  if (value == "en" || value == "ENG") return "English";
  if (value == "zh" || value == "CN") return "Simplified Chinese";
  if (value == "auto") return "the source language (detect it from the text)";
  throw std::runtime_error("Unsupported language");
}
}
JA_API void* ja_g_alloc(size_t size) { return std::malloc(size); }
JA_API void ja_g_free(void* value) { std::free(value); }
JA_API const char* ja_g_error() { return error.c_str(); }
JA_API void* ja_g_load(const char* path, const char* runtime, int threads) {
  try {
    error.clear();
    std::call_once(initialized, [runtime] {
      llama_log_set(quiet, nullptr);
      ggml_backend_load_all_from_path(runtime);
      llama_backend_init();
    });
    auto engine = std::make_unique<Engine>();
    auto params = llama_model_default_params(); params.n_gpu_layers = 0;
    engine->model = llama_model_load_from_file(path, params);
    if (!engine->model) throw std::runtime_error("Could not load GGUF model");
    auto context = llama_context_default_params();
    context.n_ctx = 4096; context.n_batch = 512; context.n_ubatch = 128;
    context.n_threads = context.n_threads_batch = std::clamp(threads, 1, 16);
    engine->context = llama_init_from_model(engine->model, context);
    if (!engine->context) throw std::runtime_error("Could not create GGUF context");
    return engine.release();
  } catch (const std::exception& e) { error = e.what(); return nullptr; }
}
JA_API void ja_g_unload(void* value) { delete static_cast<Engine*>(value); }
JA_API char* ja_g_translate(void* value, const char* input, const char* source, const char* target) {
  try {
    error.clear();
    if (!value) throw std::runtime_error("GGUF model is not loaded");
    auto& engine = *static_cast<Engine*>(value);
    const auto* vocab = llama_model_get_vocab(engine.model);
    const std::string instruction = "You are a professional translator. Translate the entire passage from "
      + language(source) + " to " + language(target)
      + ". Use the surrounding sentences to interpret terminology and pronouns. Preserve names, numbers, negation, meaning and paragraph breaks. Do not add facts, explanations or alternatives. Output only the translation.";
    llama_chat_message messages[] = {{"system", instruction.c_str()}, {"user", input}};
    const char* tmpl = llama_model_chat_template(engine.model, nullptr);
    int size = llama_chat_apply_template(tmpl, messages, 2, true, nullptr, 0);
    if (size <= 0) throw std::runtime_error("Unsupported model chat template");
    std::vector<char> prompt(size + 1);
    size = llama_chat_apply_template(tmpl, messages, 2, true, prompt.data(), static_cast<int>(prompt.size()));
    int count = -llama_tokenize(vocab, prompt.data(), size, nullptr, 0, true, true);
    if (count <= 0 || count > 3072) throw std::runtime_error("Passage exceeds GGUF context; reduce the passage length");
    std::vector<llama_token> tokens(count);
    if (llama_tokenize(vocab, prompt.data(), size, tokens.data(), count, true, true) < 0) throw std::runtime_error("GGUF tokenization failed");
    llama_memory_clear(llama_get_memory(engine.context), false);
    for (int offset = 0; offset < count; offset += 512) {
      auto batch = llama_batch_get_one(tokens.data() + offset, std::min(512, count - offset));
      if (llama_decode(engine.context, batch)) throw std::runtime_error("GGUF prompt evaluation failed");
    }
    std::unique_ptr<llama_sampler, decltype(&llama_sampler_free)> sampler(llama_sampler_init_greedy(), llama_sampler_free);
    std::string output;
    for (int i = 0; i < 1024; ++i) {
      auto token = llama_sampler_sample(sampler.get(), engine.context, -1);
      if (llama_vocab_is_eog(vocab, token)) {
        char* result = static_cast<char*>(std::malloc(output.size() + 1));
        if (!result) throw std::bad_alloc();
        std::memcpy(result, output.c_str(), output.size() + 1);
        return result;
      }
      std::vector<char> piece(128);
      int length = llama_token_to_piece(vocab, token, piece.data(), static_cast<int>(piece.size()), 0, false);
      if (length < 0) {
        piece.resize(-length);
        length = llama_token_to_piece(vocab, token, piece.data(), static_cast<int>(piece.size()), 0, false);
      }
      if (length < 0) throw std::runtime_error("GGUF token decoding failed");
      output.append(piece.data(), length);
      auto batch = llama_batch_get_one(&token, 1);
      if (llama_decode(engine.context, batch)) throw std::runtime_error("GGUF generation failed");
    }
    throw std::runtime_error("GGUF output limit reached; incomplete translation was not returned");
  } catch (const std::exception& e) { error = e.what(); return nullptr; }
}
