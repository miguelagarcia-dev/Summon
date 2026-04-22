//
//  ElevenLabsManager.swift
//  Summon
//
//  Created by Miguel Garcia on 11/9/25.
//

import Foundation

struct ElevenLabsRequest: Codable {
    let text: String
    let model_id: String
    let voice_settings: VoiceSettings
    
    struct VoiceSettings: Codable {
        let stability: Double
        let similarity_boost: Double
    }
}

enum ElevenLabsError: Error {
    case invalidURL
    case noData
    case httpError(Int, String)
    case networkError(Error)
}

class ElevenLabsManager {
    private let apiKey: String
    private let voiceID: String
    private let baseURL = "https://api.elevenlabs.io/v1/text-to-speech"
    
    // Cache repeated phrases (greetings, ack sounds) to avoid redundant API calls
    private var audioCache: [String: Data] = [:]
    
    init(apiKey: String, voiceID: String) {
        self.apiKey = apiKey
        self.voiceID = voiceID
    }
    
    // Synthesize text to speech
    func synthesize(text: String) async throws -> Data {
        // Check cache first
        if let cachedAudio = audioCache[text] {
            print("Using cached audio for: \(text)")
            return cachedAudio
        }
        
        let urlString = "\(baseURL)/\(voiceID)"
        print("🎙️ Using ElevenLabs voice ID: \(voiceID)")
        
        guard let url = URL(string: urlString) else {
            throw ElevenLabsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ElevenLabsRequest(
            text: text,
            model_id: "eleven_monolingual_v1",
            voice_settings: ElevenLabsRequest.VoiceSettings(
                stability: 0.5,
                similarity_boost: 0.8
            )
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        do {
            print("Synthesizing speech: \(text)")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ElevenLabsError.noData
            }
            
            // Check HTTP status
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("ElevenLabs API Error (\(httpResponse.statusCode)): \(errorMessage)")
                throw ElevenLabsError.httpError(httpResponse.statusCode, errorMessage)
            }
            
            // Cache the audio data
            audioCache[text] = data
            
            // Cap at 20 entries to bound memory; evict oldest (FIFO approximation)
            if audioCache.count > 20 {
                audioCache.removeValue(forKey: audioCache.keys.first!)
            }
            
            print("Successfully synthesized audio (\(data.count) bytes)")
            return data
            
        } catch let error as ElevenLabsError {
            throw error
        } catch {
            throw ElevenLabsError.networkError(error)
        }
    }
    
    // Clear the cache
    func clearCache() {
        audioCache.removeAll()
    }
}

