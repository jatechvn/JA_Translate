#include <ctranslate2/translator.h>
#include <sentencepiece_processor.h>
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#define JA_API extern "C" __declspec(dllexport)
namespace {
thread_local std::string last_error;
struct Engine {
  sentencepiece::SentencePieceProcessor source;
  sentencepiece::SentencePieceProcessor target;
  std::unique_ptr<ctranslate2::Translator> translator;
};
void check(const sentencepiece::util::Status& status) {
  if (!status.ok()) throw std::runtime_error(status.ToString());
}
}
JA_API void* ja_alloc(size_t size) { return std::malloc(size); }
JA_API void ja_free(void* ptr) { std::free(ptr); }
JA_API const char* ja_last_error() { return last_error.c_str(); }
JA_API void* ja_load(const char* model_dir, int threads) {
  try {
    last_error.clear();
    auto engine = std::make_unique<Engine>();
    const std::string path(model_dir);
    check(engine->source.Load(path + "/source.spm"));
    check(engine->target.Load(path + "/target.spm"));
    ctranslate2::ReplicaPoolConfig config;
    config.num_threads_per_replica = std::max(1, threads);
    engine->translator = std::make_unique<ctranslate2::Translator>(
      path, ctranslate2::Device::CPU, ctranslate2::ComputeType::INT8, std::vector<int>{0}, false, config);
    return engine.release();
  } catch (const std::exception& e) { last_error = e.what(); return nullptr; }
}
JA_API void ja_unload(void* ptr) { delete static_cast<Engine*>(ptr); }
JA_API int ja_token_count(void* ptr, const char* text) {
  try {
    std::vector<std::string> tokens;
    check(static_cast<Engine*>(ptr)->source.Encode(text, &tokens));
    return static_cast<int>(tokens.size());
  } catch (const std::exception& e) { last_error = e.what(); return -1; }
}
JA_API char* ja_translate(void* ptr, const char* text, const char* source_prefix) {
  try {
    last_error.clear();
    auto& engine = *static_cast<Engine*>(ptr);
    std::vector<std::string> tokens;
    check(engine.source.Encode(text, &tokens));
    if (source_prefix && source_prefix[0]) tokens.insert(tokens.begin(), source_prefix);
    // Transformers Marian conversion expects tokenizer-added EOS (config disables automatic EOS).
    tokens.emplace_back("</s>");
    if (tokens.size() > 500) throw std::runtime_error("Input exceeds model context; split it into shorter sentences");
    ctranslate2::TranslationOptions options;
    options.beam_size = 2;
    options.max_input_length = 512;
    options.max_decoding_length = 512;
    const auto results = engine.translator->translate_batch({tokens}, options);
    if (results.empty() || results[0].hypotheses.empty()) throw std::runtime_error("No translation returned");
    std::string output;
    check(engine.target.Decode(results[0].hypotheses[0], &output));
    auto result = static_cast<char*>(std::malloc(output.size() + 1));
    if (!result) throw std::bad_alloc();
    std::memcpy(result, output.c_str(), output.size() + 1);
    return result;
  } catch (const std::exception& e) { last_error = e.what(); return nullptr; }
}
