//
//  SpeechRecognizer.swift
//  Summon
//
//  Created by Miguel Garcia on 11/9/25.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: NSObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5
    private var lastTranscription: String = ""
    private var hasDetectedSpeech = false
    
    // Callback for when transcription is complete (user stops speaking)
    var onTranscriptionComplete: ((String) -> Void)?
    
    override init() {
        super.init()
    }
    
    // Request permissions for microphone and speech recognition
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        // On macOS, speech recognition permission also handles microphone access
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("speech recognition authorized")
                    completion(true)
                case .denied:
                    print("speech recognition denied")
                    completion(false)
                case .restricted:
                    print("speech recognition restricted")
                    completion(false)
                case .notDetermined:
                    print("speech recognition not determined")
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    // Start continuous listening
    func startListening() throws {
        // Cancel any ongoing recognition task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // On macOS, no explicit audio session configuration needed
        // The audio engine handles it automatically
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Get the audio input node
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                
                // Check if we have speech
                if !transcription.isEmpty {
                    self.hasDetectedSpeech = true
                    self.lastTranscription = transcription
                    print("heard: \"\(transcription)\"")
                    
                    // Reset silence timer on main thread
                    DispatchQueue.main.async {
                        self.silenceTimer?.invalidate()
                        self.silenceTimer = Timer.scheduledTimer(withTimeInterval: self.silenceThreshold, repeats: false) { [weak self] _ in
                            self?.handleSilenceDetected()
                        }
                    }
                }
                
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                if error != nil {
                    print("recognition error: \(error!.localizedDescription)")
                } else if isFinal {
                    print("recognition marked as final, session ended")
                }
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        // Configure the microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        print("speech recognition started")
        hasDetectedSpeech = false
        lastTranscription = ""
    }

    // Stop listening
    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil

        audioEngine.stop()
        recognitionRequest?.endAudio()

        if let inputNode = audioEngine.inputNode as AVAudioInputNode? {
            inputNode.removeTap(onBus: 0)
        }

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        print("speech recognition stopped")
    }

    // Handle when silence is detected (user stopped speaking)
    private func handleSilenceDetected() {
        print("silence detected")

        guard hasDetectedSpeech, !lastTranscription.isEmpty else {
            print("no speech to process")
            return
        }

        let finalTranscription = lastTranscription
        print("user finished speaking: \"\(finalTranscription)\"")
        
        // Reset state
        hasDetectedSpeech = false
        lastTranscription = ""
        
        // Call completion handler
        onTranscriptionComplete?(finalTranscription)
    }
}

