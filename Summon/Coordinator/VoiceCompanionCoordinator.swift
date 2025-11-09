//
//  VoiceCompanionCoordinator.swift
//  Summon
//
//  Created by Miguel Garcia on 11/9/25.
//

import Foundation
import AVFoundation

enum CompanionState {
    case idle
    case listening
    case thinking
    case speaking
}

class VoiceCompanionCoordinator {
    // Core components
    private let speechRecognizer: SpeechRecognizer
    private let conversationEngine: ConversationEngine
    private let elevenLabsManager: ElevenLabsManager
    private let audioPlayer: AudioPlayer
    
    // Visual feedback
    weak var renderer: ModelRenderer?
    
    // State management
    private var state: CompanionState = .idle {
        didSet {
            print("🤖 Companion state changed: \(oldValue) -> \(state)")
            // Update visual glow based on speaking state
            renderer?.isSpeaking = (state == .speaking)
        }
    }
    
    private var isActive = false
    
    init(
        claudeAPIKey: String,
        elevenLabsAPIKey: String,
        elevenLabsVoiceID: String
    ) {
        self.speechRecognizer = SpeechRecognizer()
        self.conversationEngine = ConversationEngine(apiKey: claudeAPIKey)
        self.elevenLabsManager = ElevenLabsManager(apiKey: elevenLabsAPIKey, voiceID: elevenLabsVoiceID)
        self.audioPlayer = AudioPlayer()
        
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        // Set up speech recognition callback
        speechRecognizer.onTranscriptionComplete = { [weak self] text in
            guard let self = self else { return }
            
            print("📝 User said: '\(text)'")
            
            // Handle the user's speech in a background task
            Task {
                await self.handleUserSpeech(text)
            }
        }
    }
    
    // Start the companion (request permissions and begin listening)
    func start() {
        guard !isActive else {
            print("Companion already active")
            return
        }
        
        print("🚀 Starting Voice Companion...")
        
        // Request permissions first
        speechRecognizer.requestPermissions { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                print("✅ Permissions granted - starting to listen")
                self.isActive = true
                self.startListening()
            } else {
                print("❌ Permissions denied - cannot start companion")
            }
        }
    }
    
    // Stop the companion
    func stop() {
        guard isActive else { return }
        
        print("🛑 Stopping Voice Companion")
        isActive = false
        speechRecognizer.stopListening()
        audioPlayer.stop()
        state = .idle
    }
    
    // Start listening for user speech
    private func startListening() {
        guard state != .listening else {
            print("⚠️ Already listening, skipping restart")
            return
        }
        
        guard isActive else {
            print("⚠️ Companion not active, cannot start listening")
            return
        }
        
        do {
            state = .listening
            try speechRecognizer.startListening()
            print("👂 Listening for your voice...")
        } catch {
            print("❌ Failed to start listening: \(error.localizedDescription)")
            state = .idle
        }
    }
    
    // Handle user speech input
    func handleUserSpeech(_ text: String) async {
        // Prevent handling new input while busy
        guard state == .listening else {
            print("⚠️ Ignoring input - currently \(state)")
            return
        }
        
        // Stop listening while we process
        speechRecognizer.stopListening()
        
        do {
            // Get AI response
            state = .thinking
            print("🤔 Thinking...")
            let response = try await conversationEngine.getResponse(userMessage: text)
            
            // Synthesize speech
            print("🎤 Synthesizing response...")
            let audioData = try await elevenLabsManager.synthesize(text: response)
            
            // Speak the response
            state = .speaking
            print("🗣️ Speaking: '\(response)'")
            
            // Play audio with completion handler
            audioPlayer.play(audioData: audioData) { [weak self] in
                guard let self = self else { return }
                print("✅ Finished speaking")
                
                // Resume listening after speaking
                if self.isActive {
                    self.startListening()
                } else {
                    self.state = .idle
                }
            }
            
        } catch {
            print("❌ Error in conversation flow: \(error.localizedDescription)")
            state = .idle
            
            // Resume listening on error
            if isActive {
                startListening()
            }
        }
    }
    
    // Manually trigger a conversation (for testing)
    func testConversation(message: String) async {
        await handleUserSpeech(message)
    }
    
    // Get current state
    var currentState: CompanionState {
        return state
    }
}

