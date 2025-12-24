//
//  OpenRouterChatAPI.swift
//  Indooe nav 4 good
//
//  Created by vincent deng on 9/11/2025.
//

import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let extra_headers: [String: String]
    let extra_body: [String: String]
    let model: String
    let messages: [ChatMessage]
}

struct ChatCompletionChoice: Codable {
    struct Message: Codable {
        let content: String
    }
    let message: Message
}

struct ChatCompletionResponse: Codable {
    let choices: [ChatCompletionChoice]
}

struct APIErrorResponse: Decodable {
    struct ErrorDetail: Decodable {
        let message: String
        let code: Int?
        let provider_name: String?
    }
    let error: ErrorDetail
}

enum OpenRouterError: Error {
    case invalidResponse
    case apiError(message: String, code: Int?, providerName: String?)
    case decodingError(Error)
}

class OpenRouterAPI {
    private let apiKey: String
    private let baseURL = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
    private let session = URLSession.shared

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendChat(
        userPrompt: String,
        referer: String? = nil,
        title: String? = nil
    ) async throws -> String {
        // Prepare headers
        var headers: [String: String] = [:]
        if let referer = referer {
            headers["HTTP-Referer"] = referer
        }
        if let title = title {
            headers["X-Title"] = title
        }

        let messages = [
            ChatMessage(role: "user", content: userPrompt)
        ]

        let chatRequest = ChatRequest(
            extra_headers: headers,
            extra_body: [:],
            model: "google/gemma-3-27b-it:free",
            messages: messages
        )

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode request body
        do {
            let bodyData = try JSONEncoder().encode(chatRequest)
            request.httpBody = bodyData
        } catch {
            throw error
        }

        // Send request using async/await
        let (data, response) = try await session.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }
        
        // Try decoding as success response first
        if let chatResponse = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
           let content = chatResponse.choices.first?.message.content {
            return content
        }
        
        // If success response fails, try decoding as error response
        do {
            let apiError = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw OpenRouterError.apiError(
                message: apiError.error.message,
                code: apiError.error.code,
                providerName: apiError.error.provider_name
            )
        } catch let decodingError as DecodingError {
            throw OpenRouterError.decodingError(decodingError)
        } catch {
            throw error
        }
    }
}
