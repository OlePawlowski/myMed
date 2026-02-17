//
//  MedGemmaBridge.mm
//  MyMed
//
//  Objective-C++ Bridge zu llama.cpp – vollständige Inference Loop.
//  iOS: Apple TN2434 + Metal 2GB-Limit → CPU-only, mmap, minimale Kontextgröße.
//

#import "MedGemmaBridge.h"
#import <llama/llama.h>

#import <string>
#import <vector>
#import <cstring>

@interface MedGemmaBridge () {
    llama_model * _model;
    llama_context * _ctx;
    const llama_vocab * _vocab;
    llama_sampler * _sampler;
}
@end

@implementation MedGemmaBridge

- (nullable instancetype)initWithModelPath:(NSString *)path {
    self = [super init];
    if (!self) return nil;

    llama_log_set([](enum ggml_log_level level, const char * text, void * /* user_data */) {
        if (level >= GGML_LOG_LEVEL_ERROR) {
            fprintf(stderr, "llama: %s", text);
        }
    }, nullptr);

    ggml_backend_load_all();

    llama_model_params model_params = llama_model_default_params();
#if TARGET_OS_SIMULATOR
    model_params.n_gpu_layers = 0;
#else
    // iOS: MedGemma 4B für iPhones mit 6 GB+ RAM – Metal für Geschwindigkeit
    model_params.n_gpu_layers = 20;
    model_params.use_mmap = true;
    model_params.use_mlock = false;
#endif

    _model = llama_model_load_from_file([path UTF8String], model_params);
    if (!_model) {
        fprintf(stderr, "MedGemmaBridge: Konnte Modell nicht laden: %s\n", [path UTF8String]);
        return nil;
    }

    _vocab = llama_model_get_vocab(_model);

    int n_threads = (int)[NSProcessInfo processInfo].processorCount;
    if (n_threads <= 0) n_threads = 4;

    llama_context_params ctx_params = llama_context_default_params();
#if TARGET_OS_SIMULATOR
    ctx_params.n_ctx = 4096;
    ctx_params.n_batch = 512;
#else
    // iOS: 6 GB+ RAM (ab iPhone 14) – MedGemma 4B mit Metal
    ctx_params.n_ctx = 2048;
    ctx_params.n_batch = 256;
#endif
    ctx_params.n_threads = n_threads;
    ctx_params.n_threads_batch = n_threads;

    _ctx = llama_init_from_model(_model, ctx_params);
    if (!_ctx) {
        fprintf(stderr, "MedGemmaBridge: Konnte Context nicht erstellen\n");
        llama_model_free(_model);
        _model = nullptr;
        return nil;
    }

    // Sampler: medizinisch optimiert (weniger Halluzinationen)
    // temperature 0.3, top_p 0.9, repeat_penalty 1.1
    auto sparams = llama_sampler_chain_default_params();
    sparams.no_perf = true;
    _sampler = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(_sampler, llama_sampler_init_penalties(64, 1.1f, 0.0f, 0.0f));
    llama_sampler_chain_add(_sampler, llama_sampler_init_top_p(0.9f, 1));
    llama_sampler_chain_add(_sampler, llama_sampler_init_temp(0.3f));
    llama_sampler_chain_add(_sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    return self;
}

- (void)dealloc {
    if (_sampler) {
        llama_sampler_free(_sampler);
        _sampler = nullptr;
    }
    if (_ctx) {
        llama_free(_ctx);
        _ctx = nullptr;
    }
    if (_model) {
        llama_model_free(_model);
        _model = nullptr;
    }
    llama_backend_free();
}

- (nullable NSString *)generateResponse:(NSString *)prompt {
    if (!_ctx || !_vocab) return nil;

    const char * c_prompt = [prompt UTF8String];
    size_t prompt_len = strlen(c_prompt);

    // Tokenisierung
    const int n_prompt = -llama_tokenize(_vocab, c_prompt, (int)prompt_len, nullptr, 0, true, true);
    if (n_prompt <= 0) return @"";

    std::vector<llama_token> prompt_tokens((size_t)n_prompt);
    if (llama_tokenize(_vocab, c_prompt, (int)prompt_len, prompt_tokens.data(), (int)prompt_tokens.size(), true, true) < 0) {
        return nil;
    }

    const int max_prompt = TARGET_OS_SIMULATOR ? 2048 : 1024;
    if (n_prompt > max_prompt) {
        prompt_tokens.resize((size_t)max_prompt);
    }

    const int n_ctx = llama_n_ctx(_ctx);
#if TARGET_OS_SIMULATOR
    const int max_predict = 512;
#else
    const int max_predict = 256;  // iOS: mit kleinem Modell mehr Spielraum
#endif
    const int n_predict = (int)std::min((size_t)max_predict, (size_t)(n_ctx - (int)prompt_tokens.size() - 1));
    if (n_predict <= 0) return @"";

    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), (int)prompt_tokens.size());

    // Encoder-Decoder Modelle (z.B. MedGemma)
    if (llama_model_has_encoder(_model)) {
        if (llama_encode(_ctx, batch) != 0) return nil;
        llama_token decoder_start = llama_model_decoder_start_token(_model);
        if (decoder_start == LLAMA_TOKEN_NULL) decoder_start = llama_vocab_bos(_vocab);
        batch = llama_batch_get_one(&decoder_start, 1);
    }

    std::string output;

    for (int i = 0; i < n_predict; ++i) {
        if (llama_decode(_ctx, batch) != 0) break;

        llama_token new_token = llama_sampler_sample(_sampler, _ctx, -1);
        if (llama_vocab_is_eog(_vocab, new_token)) break;

        char buf[256];
        int n = llama_token_to_piece(_vocab, new_token, buf, sizeof(buf), 0, true);
        if (n > 0) {
            output.append(buf, (size_t)n);
        }

        batch = llama_batch_get_one(&new_token, 1);
    }

    return [NSString stringWithUTF8String:output.c_str()];
}

- (void)generateResponse:(NSString *)prompt tokenCallback:(void (^)(NSString * _Nullable))tokenCallback {
    if (!_ctx || !_vocab || !tokenCallback) return;

    const char * c_prompt = [prompt UTF8String];
    size_t prompt_len = strlen(c_prompt);

    const int n_prompt = -llama_tokenize(_vocab, c_prompt, (int)prompt_len, nullptr, 0, true, true);
    if (n_prompt <= 0) { tokenCallback(nil); return; }

    std::vector<llama_token> prompt_tokens((size_t)n_prompt);
    if (llama_tokenize(_vocab, c_prompt, (int)prompt_len, prompt_tokens.data(), (int)prompt_tokens.size(), true, true) < 0) {
        tokenCallback(nil);
        return;
    }

    const int max_prompt = TARGET_OS_SIMULATOR ? 2048 : 1024;
    if (n_prompt > max_prompt) prompt_tokens.resize((size_t)max_prompt);

    const int n_ctx = llama_n_ctx(_ctx);
    const int max_predict = TARGET_OS_SIMULATOR ? 512 : 256;
    const int n_predict = (int)std::min((size_t)max_predict, (size_t)(n_ctx - (int)prompt_tokens.size() - 1));
    if (n_predict <= 0) { tokenCallback(nil); return; }

    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), (int)prompt_tokens.size());

    if (llama_model_has_encoder(_model)) {
        if (llama_encode(_ctx, batch) != 0) { tokenCallback(nil); return; }
        llama_token decoder_start = llama_model_decoder_start_token(_model);
        if (decoder_start == LLAMA_TOKEN_NULL) decoder_start = llama_vocab_bos(_vocab);
        batch = llama_batch_get_one(&decoder_start, 1);
    }

    for (int i = 0; i < n_predict; ++i) {
        if (llama_decode(_ctx, batch) != 0) break;

        llama_token new_token = llama_sampler_sample(_sampler, _ctx, -1);
        if (llama_vocab_is_eog(_vocab, new_token)) break;

        char buf[256];
        int n = llama_token_to_piece(_vocab, new_token, buf, sizeof(buf), 0, true);
        if (n > 0 && n < (int)sizeof(buf)) {
            buf[n] = '\0';
            tokenCallback([NSString stringWithUTF8String:buf]);
        }

        batch = llama_batch_get_one(&new_token, 1);
    }
    tokenCallback(nil);
}

@end
