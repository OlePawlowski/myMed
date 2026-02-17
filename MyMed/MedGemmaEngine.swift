//
//  MedGemmaEngine.swift
//  MyMed
//
//  Lokale MedGemma 4B Inferenz – für iPhones mit 6 GB+ RAM (ab iPhone 14).
//  Server-Version für 4 GB Geräte kommt später.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Engine für lokale MedGemma 4B Inferenz (llama.cpp + Metal).
final class MedGemmaEngine {

    private var bridge: MedGemmaBridge?

    private static let modelCandidates: [(base: String, ext: String)] = [
        ("medgemma-4b-instruct.Q4_K_M", "gguf"),
        ("medgemma-4b-instruct", "gguf"),
    ]

    private static let systemPrompt = """
    Du bist ein medizinischer Assistent.
    Antworte sachlich, vorsichtig und ohne Diagnosen zu stellen.
    Gib keine medizinischen Ratschläge, die einen Arztbesuch ersetzen könnten.
    """

    init() {
        #if canImport(UIKit)
        // Apple TN2434: Auf Speicherwarnung reagieren – Modell freigeben
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.bridge = nil
        }
        #endif
    }

    /// Prüft ob ein Modell geladen werden kann.
    var isAvailable: Bool {
        modelPath != nil
    }

    /// Pfad zur Modell-Datei – durchsucht Bundle und Documents.
    private var modelPath: String? {
        for candidate in Self.modelCandidates {
            if let path = Bundle.main.path(forResource: candidate.base, ofType: candidate.ext) {
                return path
            }
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        for candidate in Self.modelCandidates {
            let url = docs?.appendingPathComponent("\(candidate.base).\(candidate.ext)")
            if let p = url?.path, FileManager.default.fileExists(atPath: p) {
                return p
            }
        }
        return nil
    }

    /// Lädt das Modell beim ersten Aufruf.
    private func ensureLoaded() -> MedGemmaBridge? {
        if let b = bridge { return b }
        guard let path = modelPath else {
            print("MedGemmaEngine: Kein Modell gefunden. Bitte medgemma-4b-instruct.Q4_K_M.gguf in MyMed/Models ablegen.")
            return nil
        }
        bridge = MedGemmaBridge(modelPath: path)
        return bridge
    }

    /// MedGemma Chat-Format
    private func buildPrompt(userMessage: String) -> String {
        return "<start_of_turn>user\n\(Self.systemPrompt)\n\n\(userMessage)<end_of_turn>\n<start_of_turn>model\n"
    }

    /// Generiert eine Antwort für die User-Nachricht.
    func ask(_ userMessage: String) async -> String {
        let fullPrompt = buildPrompt(userMessage: userMessage)
        let raw = await Task.detached(priority: .userInitiated) { [weak self] in
            guard let bridge = self?.ensureLoaded() else {
                return "Modell nicht verfügbar. Erfordert iPhone mit 6 GB+ RAM. Bitte medgemma-4b-instruct.Q4_K_M.gguf in MyMed/Models ablegen."
            }
            return bridge.generateResponse(fullPrompt) ?? "Fehler bei der Generierung."
        }.value
        return Self.cleanModelOutput(raw)
    }

    /// Streamt die Antwort – Token für Token, für bessere UX während der Generierung.
    func askStreaming(_ userMessage: String, onToken: @escaping @Sendable (String) -> Void) async -> String {
        let fullPrompt = buildPrompt(userMessage: userMessage)
        var fullOutput = ""
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let bridge = self?.ensureLoaded() else {
                return
            }
            bridge.generateResponse(fullPrompt) { token in
                guard let t = token, !t.isEmpty else { return }
                fullOutput += t
                onToken(t)
            }
        }.value
        return Self.cleanModelOutput(fullOutput)
    }

    /// Entfernt Format-Artefakte aus der Modellausgabe (z.B. <end_of_turn>, User:, Assistant:).
    private static func cleanModelOutput(_ text: String) -> String {
        var result = text
            .replacingOccurrences(of: "<end_of_turn>", with: "")
            .replacingOccurrences(of: "<start_of_turn>", with: "")
        // Entferne führende "user\n" oder "Assistant:" etc.
        for prefix in ["user\n", "model\n", "User:", "Assistant:", "user:", "assistant:"] {
            if result.hasPrefix(prefix) {
                result = String(result.dropFirst(prefix.count))
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
