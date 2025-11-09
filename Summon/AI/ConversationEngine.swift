//
//  ConversationEngine.swift
//  Summon
//
//  Created by Miguel Garcia on 11/9/25.
//

import Foundation

class ConversationEngine {
    private let claudeAPI: ClaudeAPIManager
    private var conversationHistory: [ClaudeMessage] = []
    private let maxHistoryLength = 10 // Store last 10 message pairs
    
    private let systemPrompt = """
    Keep responses brief (1-2 sentences max) and speak naturally in this voice, with occasional dry humor or deadpan observations.
    
    CRITICAL: This is VOICE ONLY. NEVER use asterisks (*), brackets, parentheses, or ANY action descriptions. 
    DO NOT write things like *clears throat*, *sighs*, *chuckles*, etc. 
    ONLY write the exact words that should be spoken out loud. Nothing else.
    If you want to convey emotion, use tone in your words, not actions in asterisks.
    
    Examples of good responses:
    - "Are you really watching that? Smh."
    - "That paragraph's buns. You can do better."
    - "Interesting choice. Bold. Wrong, but bold."
    - "I'm just observing. Judging silently."
    - "You type like you're fighting your keyboard."
    """
    
    init(apiKey: String) {
        self.claudeAPI = ClaudeAPIManager(apiKey: apiKey)
    }
    
    // Get response from Claude based on user message
    func getResponse(userMessage: String) async throws -> String {
        print("ConversationEngine: Processing message: '\(userMessage)'")
        
        // Add user message to history
        let userClaudeMessage = ClaudeMessage(role: "user", content: userMessage)
        conversationHistory.append(userClaudeMessage)
        
        // Get response from Claude
        let response = try await claudeAPI.chat(
            systemPrompt: systemPrompt,
            messages: conversationHistory
        )
        
        print("ConversationEngine: Got response: '\(response)'")
        
        // Add assistant response to history
        let assistantMessage = ClaudeMessage(role: "assistant", content: response)
        conversationHistory.append(assistantMessage)
        
        // Trim history if too long (keep last N message pairs)
        trimHistory()
        
        return response
    }
    
    // Trim conversation history to maintain reasonable context length
    private func trimHistory() {
        // Each exchange is 2 messages (user + assistant)
        let maxMessages = maxHistoryLength * 2
        
        if conversationHistory.count > maxMessages {
            // Remove oldest messages but keep pairs intact
            let excessCount = conversationHistory.count - maxMessages
            conversationHistory.removeFirst(excessCount)
        }
    }
    
    // Reset conversation history
    func resetConversation() {
        conversationHistory.removeAll()
        print("ConversationEngine: Conversation history reset")
    }
    
    // Get current conversation length
    var messageCount: Int {
        return conversationHistory.count
    }
}

