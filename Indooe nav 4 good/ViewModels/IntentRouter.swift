//
//  IntentRouter.swift
//  Indooe nav 4 good
//
//  Created by vincent deng on 9/11/2025.
//
import SwiftDotenv
import Foundation
import SwiftUI

class IntentRouter {
    enum Intent: String, Codable {
        case navigation = "navigation"
        case unknown = "unknown"
    }
    
    struct IntentResult {
        let intent: Intent
        let confidence: Double
        let parameters: [String: Any]
        let origin: [String: Any]
    }
    
    func classifyIntent(from transcript: String) async -> IntentResult {
        // Use LLM with function calling
        let systemPrompt = Prompts.IntentRoutorPrompt
        
        var apiKey: String? = nil
        do {
            try Dotenv.configure(atPath: "/Users/vincentdeng/Projects/Indooe nav 4 good/.env")
            apiKey = Dotenv["OPENROUTER_API_KEY"]?.stringValue
        } catch {
            print("Could not load .env file. Error: \(error)")
            return IntentResult(intent: .unknown, confidence: 0.0, parameters: ["error": "Env file missing"], origin: [:])
        }
        
        guard let validApiKey = apiKey, !validApiKey.isEmpty else {
            print("API key is missing or empty")
            return IntentResult(intent: .unknown, confidence: 0.0, parameters: ["error": "API key missing"], origin: [:])
        }
        
        let api = OpenRouterAPI(apiKey: validApiKey)
        
        do {
            print("[\(Date())] Transcript:", transcript)
            
            let answer = try await api.sendChat(
                userPrompt: systemPrompt + transcript,
                referer: "",
                title: ""
            )
            
            print("[\(Date())] AI answer:", answer)

            // Parse JSON response
            guard let data = answer.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let intentString = json["intent"] as? String else {
                return IntentResult(
                    intent: .unknown,
                    confidence: 0.0,
                    parameters: ["error": "Invalid JSON"],
                    origin: [:]
                )
            }
            
            // Map intent string to enum
            let intent: Intent
            switch intentString {
            case "navigation":
                intent = .navigation
            default:
                intent = .unknown
            }
            
            // Extract parameters (excluding "intent" key)
            var parameters = json
            parameters.removeValue(forKey: "intent")
            
            return IntentResult(
                intent: intent,
                confidence: 1.0,
                parameters: parameters,
                origin: json
            )
            
        } catch {
            print("Error:", error)
            return IntentResult(
                intent: .unknown,
                confidence: 0.0,
                parameters: ["error": error.localizedDescription],
                origin: [:]
            )
        }

    }
    
    @ViewBuilder
    func handleIntentResult(_ result: IntentResult) -> some View {
        switch result.intent {
        case .navigation:
            handleNavigationIntent(parameters: result.parameters)
        case .unknown:
            handleUnknownIntent()
        }
    }

    func handleNavigationIntent(parameters: [String: Any]) -> some View {
        // Build the spoken text
        var spokenText = "Navigation intent detected. "
        
        let sortedKeys = parameters.keys.sorted()
        var destination = ""
        
        // First pass: extract destination if it exists
        for key in sortedKeys {
            let capitalizedKey = key.prefix(1).uppercased() + key.dropFirst()
            let value = String(describing: parameters[key]!)
            
            spokenText += "\(capitalizedKey): \(value)"
            
            if capitalizedKey == "Destination" {
                destination = value
            }
            
            // Add comma between items
            if key != sortedKeys.last {
                spokenText += ". "
            }
        }
        
        // Add navigation instruction only once at the end
        if !destination.isEmpty {
            spokenText += ". The nearest \(destination) is 1 minute away. Turn right and you should be there in one minute."
        }
        
        // Speak the text
        SpeechManager.shared.speak(spokenText)
        
        // Return the UI
        return VStack(alignment: .leading, spacing: 8) {
            Text("Navigation intent detected...")
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(sortedKeys, id: \.self) { key in
                HStack {
                    Text(key.capitalized + ":")
                        .fontWeight(.medium)
                    Text(String(describing: parameters[key]!))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    func handleUnknownIntent() -> some View {
        // Speak the error message
        SpeechManager.shared.speak("Unknown intent detected. Please try again.")
        
        // Return the UI
        return Text("Unknown intent detected. Please try again.")
            .font(.headline)
            .padding()
    }

}
