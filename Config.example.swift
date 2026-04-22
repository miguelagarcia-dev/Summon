//
//  Config.example.swift
//  Summon
//
//  Copy this file to Summon/Config.swift and fill in your real API keys,
//  or set the corresponding environment variables instead.
//
//  Config.swift is gitignored — never commit real keys.
//

import Foundation

struct Config {
    static let claudeAPIKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] ?? "YOUR_CLAUDE_API_KEY_HERE"
    static let elevenLabsAPIKey = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? "YOUR_ELEVENLABS_API_KEY_HERE"
    static let elevenLabsVoiceID = ProcessInfo.processInfo.environment["ELEVENLABS_VOICE_ID"] ?? "YOUR_ELEVENLABS_VOICE_ID_HERE"
}
