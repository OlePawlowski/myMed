//
//  MedGemmaBridge.h
//  MyMed
//
//  Objective-C++ Bridge zu llama.cpp für lokale MedGemma-Inferenz.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MedGemmaBridge : NSObject

/// Initialisiert die Bridge mit dem Modell-Pfad.
/// @param path Vollständiger Pfad zur .gguf Datei (z.B. medgemma-4b-instruct.Q4_K_M.gguf)
/// @return nil wenn das Modell nicht geladen werden konnte
- (nullable instancetype)initWithModelPath:(NSString *)path;

/// Generiert eine Antwort für den gegebenen Prompt.
/// @param prompt Der vollständige Prompt (inkl. System-Prompt und User-Nachricht)
/// @return Die generierte Antwort oder nil bei Fehler
- (nullable NSString *)generateResponse:(NSString *)prompt;

/// Generiert eine Antwort und ruft für jedes Token den Callback auf.
/// @param prompt Der vollständige Prompt
/// @param tokenCallback Wird für jedes generierte Token aufgerufen (nil = Ende)
- (void)generateResponse:(NSString *)prompt tokenCallback:(void (^)(NSString * _Nullable token))tokenCallback;

@end

NS_ASSUME_NONNULL_END
