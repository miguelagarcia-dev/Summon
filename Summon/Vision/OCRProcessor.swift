//
//  OCRProcessor.swift
//  Summon
//
//  Vision framework text extraction
//

import Vision
import CoreImage

class OCRProcessor {
    private let maxTextLength = 500  // Limit for Claude context
    
    // Process image and extract text
    func extractText(from image: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // Create vision request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                // Extract and join text
                let text = self.processObservations(observations)
                continuation.resume(returning: text)
            }
            
            // Configure for speed over accuracy
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false
            
            // Perform request
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> String {
        var allText: [String] = []
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else {
                continue
            }
            
            let text = candidate.string
            
            // Filter out noise
            if isValidText(text) {
                allText.append(text)
            }
        }
        
        // Join and limit length
        let combined = allText.joined(separator: " ")
        
        if combined.count > maxTextLength {
            return String(combined.prefix(maxTextLength))
        }
        
        return combined
    }
    
    private func isValidText(_ text: String) -> Bool {
        // Filter out very short text
        guard text.count > 2 else { return false }
        
        // Filter out common UI noise
        let noise = ["...", "•", "▸", "×"]
        if noise.contains(text) { return false }
        
        // Must have at least one letter
        return text.contains(where: { $0.isLetter })
    }
}

