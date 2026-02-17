//
//  ChatViewModel.swift
//  MyMed
//
//  ViewModel für den KI-Chat – lokales MedGemma 4B (iPhones mit 6 GB+ RAM).
//

import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String

    enum Role {
        case user
        case assistant
    }
}

@MainActor
@Observable
final class ChatViewModel {

    var messages: [ChatMessage] = []
    var isLoading = false
    var streamingText = ""

    private let engine = MedGemmaEngine()

    var isModelAvailable: Bool {
        engine.isAvailable
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(role: .user, text: trimmed))
        isLoading = true
        streamingText = ""

        Task {
            let reply = await engine.askStreaming(trimmed) { [weak self] token in
                Task { @MainActor in
                    self?.streamingText += token
                }
            }
            messages.append(ChatMessage(role: .assistant, text: reply))
            isLoading = false
            streamingText = ""
        }
    }
}
