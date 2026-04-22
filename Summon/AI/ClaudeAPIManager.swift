//
//  ClaudeAPIManager.swift
//  Summon
//
//  Created by Miguel Garcia on 11/9/25.
//

import Foundation

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeRequest: Codable {
    let model: String
    let max_tokens: Int
    let temperature: Double
    let system: String
    let messages: [ClaudeMessage]
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stop_reason: String?
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

enum ClaudeAPIError: Error {
    case invalidURL
    case noData
    case decodingError(String)
    case httpError(Int, String)
    case networkError(Error)
}

class ClaudeAPIManager {
    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    // Haiku: lowest latency and cost — voice replies must feel instant
    private let model = "claude-3-haiku-20240307"
    private let maxRetries = 3
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // Main chat method
    func chat(systemPrompt: String, messages: [ClaudeMessage]) async throws -> String {
        print("🔵 ClaudeAPIManager.chat() called with \(messages.count) messages")
        var lastError: Error?
        
        // Retry logic
        for attempt in 1...maxRetries {
            do {
                return try await performRequest(systemPrompt: systemPrompt, messages: messages)
            } catch let error as ClaudeAPIError {
                lastError = error
                switch error {
                case .invalidURL:
                    print("❌ Claude API attempt \(attempt): Invalid URL")
                case .noData:
                    print("❌ Claude API attempt \(attempt): No data received")
                case .decodingError(let msg):
                    print("❌ Claude API attempt \(attempt): Decoding error - \(msg)")
                case .httpError(let code, let msg):
                    print("❌ Claude API attempt \(attempt): HTTP \(code) - \(msg)")
                case .networkError(let err):
                    print("❌ Claude API attempt \(attempt): Network error - \(err.localizedDescription)")
                }
                
                if attempt < maxRetries {
                    // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
                }
            } catch {
                lastError = error
                print("❌ Claude API attempt \(attempt): Unexpected error - \(error)")
                
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? ClaudeAPIError.networkError(NSError(domain: "ClaudeAPI", code: -1))
    }
    
    private func performRequest(systemPrompt: String, messages: [ClaudeMessage]) async throws -> String {
        guard let url = URL(string: apiURL) else {
            throw ClaudeAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        
        let requestBody = ClaudeRequest(
            model: model,
            max_tokens: 200,   // Short replies — spoken words; verbosity kills the UX
            temperature: 0.8,  // Slight creativity so the companion doesn't sound robotic
            system: systemPrompt,
            messages: messages
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("✅ Request body encoded successfully")
        } catch {
            print("❌ Failed to encode request body: \(error)")
            throw ClaudeAPIError.networkError(error)
        }
        
        print("🌐 Calling Claude API at \(apiURL)...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("📥 Received response: \(data.count) bytes")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClaudeAPIError.noData
            }
            
            // Check HTTP status
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw ClaudeAPIError.httpError(httpResponse.statusCode, errorMessage)
            }
            
            // Decode response
            let decoder = JSONDecoder()
            let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)
            
            // Extract text from content
            guard let firstContent = claudeResponse.content.first else {
                throw ClaudeAPIError.decodingError("No content in response")
            }
            
            return firstContent.text
            
        } catch let error as ClaudeAPIError {
            throw error
        } catch {
            throw ClaudeAPIError.networkError(error)
        }
    }
}

