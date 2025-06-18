//
//  AIConversationManager.swift
//  localVoiceAI
//
//  Created by Skryang on 2025/5/26.
//

import Foundation

struct ChatMessage: Codable, Identifiable {
    var id = UUID()
    let role: String // "user" or "assistant"
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let stream: Bool? // 可选，用于流式
}

struct ChatResponse: Codable {
    struct Choice: Codable {
        let message: ChatMessage
    }

    let choices: [Choice]
}

struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }

        let index: Int
        let message: Message
        let finish_reason: String
    }

    let id: String
    let object: String
    let created: Int
    let model: String
    let system_fingerprint: String
    let choices: [Choice]
}

@MainActor
class AIConversationManager: ObservableObject {
    // chat messages
    @Published var messages: [ChatMessage] = []
    @Published var isResponding: Bool = false
    @Published var latestResponseBlock: ((String) -> Void)?
    
    // Ollama API endpoint
    private let endpoint = URL(string: "http://192.168.10.34:11434/v1/chat/completions")!

    func setMessage(_ userInput: String) async {
        let userMessage = ChatMessage(role: "user", content: userInput)
        self.messages.append(userMessage)
        self.isResponding = true

        sendMessageToOllama(userInput)
    }
    
    func sendMessageToOllama(_ message: String) {
        guard let url = URL(string: "http://192.168.10.34:11434/v1/chat/completions") else {
            print("❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "llama3.2",  // 或者你用的模型名，例如 "llama3.2"
            "messages": [
                ["role": "user", "content": message]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Request error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("❌ No response data")
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
                if let reply = decoded.choices.first?.message.content {
                    // 如果你想在主线程更新 UI：
                    DispatchQueue.main.async {
                        // 更新 SwiftUI 状态，比如：
                        self.messages.append(ChatMessage(role: "assistant", content: reply))
                        self.latestResponseBlock?(reply)
                    }
                }
            } catch {
                print("❌ JSON decode error: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("⚠️ Raw JSON: \(raw)")
                }
            }
        }.resume()
    }

}
