//
//  ActivityMonitor.swift
//  Summon
//
//  Detect patterns and trigger proactive commentary
//

import Foundation

enum ActivityTrigger {
    case longSession(app: String, duration: TimeInterval)
    case focusedWork(app: String, duration: TimeInterval)
    case significantChange(from: String, to: String)
    case periodCheck(context: String)
    
    var description: String {
        switch self {
        case .longSession(let app, let duration):
            return "Long session in \(app) for \(Int(duration/60)) minutes"
        case .focusedWork(let app, let duration):
            return "Focused work in \(app) for \(Int(duration/60)) minutes"
        case .significantChange(let from, let to):
            return "Switched from \(from) to \(to)"
        case .periodCheck(let ctx):
            return "Periodic check: \(ctx)"
        }
    }
}

class ActivityMonitor {
    private var appSessionStart: [String: Date] = [:]
    private var lastApp: String?
    private var lastCommentaryTime: Date?
    private var lastTriggerType: String?
    private let commentaryCooldown: TimeInterval = 600.0  // 10 min between comments (longer is better!)
    
    // Track engagement for learning
    private var engagementCount = 0
    private var ignoredCount = 0
    
    // Analyze context and detect triggers
    func analyzeActivity(aggregator: ContextAggregator) async -> ActivityTrigger? {
        // Don't spam - respect cooldown
        if let lastTime = lastCommentaryTime,
           Date().timeIntervalSince(lastTime) < commentaryCooldown {
            return nil
        }
        
        guard let currentApp = aggregator.currentApp else {
            return nil
        }
        
        // Detect app switches (significant change)
        if let previousApp = lastApp, previousApp != currentApp {
            lastApp = currentApp
            appSessionStart[currentApp] = Date()
            
            // Only trigger on significant switches (not minor window changes)
            if isSignificantSwitch(from: previousApp, to: currentApp) {
                return .significantChange(from: previousApp, to: currentApp)
            }
        }
        
        // Track session time
        if appSessionStart[currentApp] == nil {
            appSessionStart[currentApp] = Date()
            lastApp = currentApp
        }
        
        let sessionDuration = Date().timeIntervalSince(appSessionStart[currentApp]!)
        
        // Long session trigger (20+ minutes)
        if sessionDuration > 1200 {
            let isStable = await aggregator.isContextStable()
            if isStable {
                return .longSession(app: currentApp, duration: sessionDuration)
            }
        }
        
        // Focused work trigger (40+ minutes)
        if sessionDuration > 2400 {
            let isStable = await aggregator.isContextStable(timeWindow: 60.0)
            if isStable {
                return .focusedWork(app: currentApp, duration: sessionDuration)
            }
        }
        
        return nil
    }
    
    // Mark that commentary was triggered
    func markCommentary(trigger: ActivityTrigger) async {
        lastCommentaryTime = Date()
        lastTriggerType = trigger.description
    }
    
    // User feedback methods
    func markEngaged() async {
        engagementCount += 1
        print("📊 Engagement: \(engagementCount) engaged, \(ignoredCount) ignored")
    }
    
    func markIgnored() async {
        ignoredCount += 1
        print("📊 Engagement: \(engagementCount) engaged, \(ignoredCount) ignored")
    }
    
    // Check if app switch is significant
    private func isSignificantSwitch(from: String, to: String) -> Bool {
        // Filter out noise (system apps, notifications)
        let systemApps = ["Finder", "System Preferences", "Spotlight", "Notification Center"]
        if systemApps.contains(from) || systemApps.contains(to) {
            return false
        }
        return true
    }
    
    // Reset session for app
    func resetSession(for app: String) {
        appSessionStart[app] = nil
    }
    
    // Get statistics
    func getStatistics() async -> String {
        let engagementRate = engagementCount + ignoredCount > 0 
            ? Double(engagementCount) / Double(engagementCount + ignoredCount) * 100 
            : 0
        return "Engagement: \(engagementRate.rounded())% (\(engagementCount)/\(engagementCount + ignoredCount))"
    }
}

