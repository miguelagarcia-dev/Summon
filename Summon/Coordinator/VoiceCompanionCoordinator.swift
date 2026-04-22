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

enum CompanionMode {
    case reactive   // Only responds when user speaks
    case proactive  // Watches screen and comments
    case hybrid     // Both (default)
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
            print("companion state: \(oldValue) -> \(state)")
            // Update visual glow based on speaking state
            renderer?.isSpeaking = (state == .speaking)
        }
    }
    
    private var isActive = false
    
    // MARK: - Vision System Properties
    
    private var screenCaptureManager: ScreenCaptureManager?
    private var contextAggregator: ContextAggregator?
    private var activityMonitor: ActivityMonitor?
    
    private var mode: CompanionMode = .hybrid
    private var contextMonitoringTask: Task<Void, Never>?
    private var isVisionEnabled = false
    
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
            
            print("user said: '\(text)'")
            
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
        
        print("starting voice companion")
        
        // Request permissions first
        speechRecognizer.requestPermissions { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                print("permissions granted, starting to listen")
                self.isActive = true
                self.startListening()
            } else {
                print("permissions denied, cannot start")
            }
        }
    }
    
    // Stop the companion
    func stop() {
        guard isActive else { return }
        
        print("stopping voice companion")
        isActive = false
        speechRecognizer.stopListening()
        audioPlayer.stop()
        state = .idle
    }
    
    // Start listening for user speech
    private func startListening() {
        guard state != .listening else {
            print("already listening, skipping restart")
            return
        }

        guard isActive else {
            print("companion not active, cannot start listening")
            return
        }

        do {
            state = .listening
            try speechRecognizer.startListening()
            print("listening")
        } catch {
            print("failed to start listening: \(error.localizedDescription)")
            state = .idle
        }
    }
    
    // Handle user speech input
    func handleUserSpeech(_ text: String) async {
        // Prevent handling new input while busy
        guard state == .listening else {
            print("ignoring input, currently \(state)")
            return
        }
        
        // Stop listening while we process
        speechRecognizer.stopListening()
        
        do {
            // Get AI response
            state = .thinking
            print("thinking")
            let response = try await conversationEngine.getResponse(userMessage: text)

            // Synthesize speech
            print("synthesizing response")
            let audioData = try await elevenLabsManager.synthesize(text: response)

            // Speak the response
            state = .speaking
            print("speaking: '\(response)'")
            
            // Play audio with completion handler
            audioPlayer.play(audioData: audioData) { [weak self] in
                guard let self = self else { return }
                print("finished speaking")
                
                // Resume listening after speaking
                if self.isActive {
                    self.startListening()
                } else {
                    self.state = .idle
                }
            }
            
        } catch {
            print("error in conversation flow: \(error.localizedDescription)")
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
    
    // MARK: - Vision System Methods
    
    /// Enable context-aware vision system
    func enableVision() async {
        guard !isVisionEnabled else {
            print("vision already enabled")
            return
        }

        print("enabling vision system...")
        
        do {
            // Initialize components
            screenCaptureManager = ScreenCaptureManager()
            contextAggregator = ContextAggregator()
            activityMonitor = ActivityMonitor()
            
            // Request screen recording permission
            guard let manager = screenCaptureManager,
                  try await manager.requestPermission() else {
                print("screen recording permission denied")
                return
            }
            
            // Set up frame capture callback
            manager.onFrameCaptured = { [weak self] image in
                guard let self = self,
                      let aggregator = self.contextAggregator else {
                    return
                }
                
                Task {
                    await aggregator.processCapture(image)
                }
            }
            
            // Set up error callback
            manager.onError = { error in
                print("screen capture error: \(error.localizedDescription)")
            }
            
            // Start capturing
            try await manager.startCapture()
            
            // Start activity monitoring
            startActivityMonitoring()
            
            isVisionEnabled = true
            print("vision system enabled")

        } catch {
            print("failed to enable vision: \(error.localizedDescription)")
        }
    }
    
    /// Disable vision system
    func disableVision() async {
        guard isVisionEnabled else { return }
        
        print("disabling vision system")
        
        // Stop monitoring
        contextMonitoringTask?.cancel()
        contextMonitoringTask = nil
        
        // Stop screen capture
        await screenCaptureManager?.stopCapture()
        
        // Clean up
        screenCaptureManager = nil
        contextAggregator = nil
        activityMonitor = nil
        
        isVisionEnabled = false
        print("vision system disabled")
    }
    
    // MARK: - Activity Monitoring
    
    private func startActivityMonitoring() {
        // Check for activity triggers every 30 seconds
        contextMonitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                // Wait 30 seconds
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                
                // Check for triggers
                await self?.checkForActivityTriggers()
            }
        }
    }
    
    private func checkForActivityTriggers() async {
        // Don't trigger if not in proactive/hybrid mode
        guard mode != .reactive else { return }
        
        // Don't interrupt active speech/listening
        guard state == .idle else { return }
        
        guard let aggregator = contextAggregator,
              let monitor = activityMonitor else {
            return
        }
        
        // Analyze activity
        guard let trigger = await monitor.analyzeActivity(aggregator: aggregator) else {
            return
        }
        
        print("activity trigger: \(trigger.description)")
        
        // Generate proactive comment
        await handleActivityTrigger(trigger)
    }
    
    private func handleActivityTrigger(_ trigger: ActivityTrigger) async {
        guard let aggregator = contextAggregator,
              let monitor = activityMonitor else {
            return
        }
        
        // Build context-aware message
        let context = await aggregator.buildDetailedContext()
        let userMessage = buildPromptForTrigger(trigger, context: context)
        
        do {
            state = .thinking
            
            // Get AI response
            let response = try await conversationEngine.getResponse(
                userMessage: userMessage
            )
            
            // Synthesize speech
            let audioData = try await elevenLabsManager.synthesize(text: response)
            
            state = .speaking
            print("proactive comment: '\(response)'")
            
            // Play audio
            audioPlayer.play(audioData: audioData) { [weak self] in
                self?.state = .idle
            }
            
            // Mark successful commentary
            await monitor.markCommentary(trigger: trigger)
            
        } catch {
            print("error in proactive commentary: \(error.localizedDescription)")
            state = .idle
        }
    }
    
    // MARK: - Prompt Building
    
    private func buildPromptForTrigger(
        _ trigger: ActivityTrigger,
        context: String
    ) -> String {
        let basePrompt = """
        You are a helpful AI companion monitoring the user's activity.
        Make a brief, natural observation or offer help.
        Keep it under 25 words. Be casual and friendly.
        
        Context:
        \(context)
        
        """
        
        switch trigger {
        case .longSession(let app, let duration):
            let minutes = Int(duration / 60)
            return basePrompt + """
            Observation: User has been working in \(app) for \(minutes) minutes.
            Suggest a brief check-in or offer assistance.
            """
            
        case .focusedWork(let app, let duration):
            let minutes = Int(duration / 60)
            return basePrompt + """
            Observation: Deep focus session in \(app) for \(minutes) minutes.
            Make a brief encouraging comment or offer help.
            """
            
        case .significantChange(let from, let to):
            return basePrompt + """
            Observation: User switched from \(from) to \(to).
            Brief comment if relevant, otherwise stay silent.
            """
            
        case .periodCheck(let ctx):
            return basePrompt + """
            Periodic check-in.
            Make a very brief observation about their work.
            """
        }
    }
    
    // MARK: - Mode Control
    
    func setMode(_ mode: CompanionMode) {
        self.mode = mode
        print("companion mode: \(mode)")
    }
    
    // MARK: - User Feedback
    
    /// Call this when user responds to proactive comment
    func userEngagedWithComment() async {
        await activityMonitor?.markEngaged()
    }
    
    /// Call this when user dismisses or ignores comment
    func userIgnoredComment() async {
        await activityMonitor?.markIgnored()
    }
}

