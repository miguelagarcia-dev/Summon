//
//  AudioPlayer.swift
//  Summon
//
//  Created by Miguel Garcia on 11/9/25.
//

import Foundation
import AVFoundation

class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    private var audioQueue: [(Data, (() -> Void)?)] = []
    private var isPlaying = false
    
    override init() {
        super.init()
        // No audio session setup needed on macOS - it's handled automatically
        print("AudioPlayer initialized for macOS")
    }
    
    // Play audio data with completion callback
    func play(audioData: Data, completion: (() -> Void)? = nil) {
        // Add to queue
        audioQueue.append((audioData, completion))
        
        // If not currently playing, start playing
        if !isPlaying {
            playNext()
        }
    }
    
    private func playNext() {
        guard !audioQueue.isEmpty else {
            isPlaying = false
            return
        }
        
        isPlaying = true
        let (audioData, completion) = audioQueue.removeFirst()
        
        do {
            // Create audio player from data
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            
            // Store completion in associated object pattern
            // We'll use the audioPlayer's delegate callbacks instead
            objc_setAssociatedObject(
                audioPlayer as Any,
                &completionKey,
                completion as Any?,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            
            print("Playing audio (\(audioData.count) bytes)")
            audioPlayer?.play()
            
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
            completion?()
            
            // Try next in queue
            playNext()
        }
    }
    
    // Stop current playback
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        audioQueue.removeAll()
        isPlaying = false
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Audio playback finished")
        
        // Get completion from associated object
        let completion = objc_getAssociatedObject(player, &completionKey) as? (() -> Void)
        completion?()
        
        // Play next in queue
        playNext()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "unknown")")
        
        // Get completion from associated object
        let completion = objc_getAssociatedObject(player, &completionKey) as? (() -> Void)
        completion?()
        
        // Try next in queue
        playNext()
    }
}

// Key for associated object storage
private var completionKey: UInt8 = 0

