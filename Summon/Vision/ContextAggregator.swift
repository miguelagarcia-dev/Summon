//
//  ContextAggregator.swift
//  Summon
//
//  Combine screen text + window info into meaningful context
//

import Foundation
import CoreGraphics

struct ContextSnapshot {
    let windowContext: WindowContext
    let screenText: String
    let timestamp: Date
}

class ContextAggregator {
    // Rolling buffer: 20 snapshots keeps ~10s of history without unbounded memory growth
    private var snapshots: [ContextSnapshot] = []
    private let maxSnapshots = 20
    private let ocrProcessor = OCRProcessor()
    let windowManager = WindowContextManager()
    
    // Process a new screen capture
    func processCapture(_ image: CGImage) async {
        // Extract text
        let text = (try? await ocrProcessor.extractText(from: image)) ?? ""
        
        // Get window context
        guard let windowContext = windowManager.getCurrentContext() else {
            return
        }
        
        // Create snapshot
        let snapshot = ContextSnapshot(
            windowContext: windowContext,
            screenText: text,
            timestamp: Date()
        )
        
        // Store
        snapshots.append(snapshot)
        
        // Trim old snapshots
        if snapshots.count > maxSnapshots {
            snapshots.removeFirst()
        }
        
        print("📊 Context: \(windowContext.appName) - \(text.prefix(50))...")
    }
    
    // Build context summary for AI
    func buildContextSummary() -> String {
        guard !snapshots.isEmpty else {
            return "No context available"
        }
        
        let latest = snapshots.last!
        
        // Get recent text (last 3 snapshots)
        let recentSnapshots = Array(snapshots.suffix(3))
        let recentText = recentSnapshots
            .map { $0.screenText }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        // Build summary
        var summary = "Current: \(latest.windowContext.appName)"
        
        if let title = latest.windowContext.windowTitle, !title.isEmpty {
            summary += " - \(title)"
        }
        
        if !recentText.isEmpty {
            let cleanText = recentText
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
                .prefix(200)
            
            summary += "\nRecent text: \(cleanText)"
        }
        
        return summary
    }
    
    // async to allow future enrichment (e.g. network lookups, ML inference)
    func buildDetailedContext() async -> String {
        return buildContextSummary()
    }
    
    // Get current app
    var currentApp: String? {
        return snapshots.last?.windowContext.appName
    }
    
    // Check if context is stable
    func isContextStable(timeWindow: TimeInterval = 30.0) async -> Bool {
        guard snapshots.count >= 3 else { return false }
        
        let recent = snapshots.suffix(5)
        let appNames = Set(recent.map { $0.windowContext.appName })
        
        return appNames.count == 1  // Same app for recent snapshots
    }
}

