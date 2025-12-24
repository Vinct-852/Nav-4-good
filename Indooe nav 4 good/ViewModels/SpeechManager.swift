//
//  SpeechManager.swift
//  Indooe nav 4 good
//
//  Created by vincent deng on 23/12/2025.
//

import AVFoundation
import Foundation

class SpeechManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    /// Speak text in English with configurable rate and volume
    func speak(
        _ text: String,
        language: String = "en-US",
        rate: Float = AVSpeechUtteranceDefaultSpeechRate,
        volume: Float = 1.0,
        pitch: Float = 1.0
    ) {
        // Don't speak empty strings
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        // Create speech utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure speech properties
        utterance.rate = rate
        utterance.volume = volume
        utterance.pitchMultiplier = pitch
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        
        // Speak the utterance
        if !synthesizer.isSpeaking {
            synthesizer.speak(utterance)
        }
    }
    
    /// Stop current speech
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    /// Pause current speech
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    /// Resume paused speech
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didStart utterance: AVSpeechUtterance
    ) {
        print("[\(Date())] Speech started: \(utterance.speechString)")
    }
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        print("[\(Date())] Speech finished: \(utterance.speechString)")
    }
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didPause utterance: AVSpeechUtterance
    ) {
        print("[\(Date())] Speech paused: \(utterance.speechString)")
    }
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didContinue utterance: AVSpeechUtterance
    ) {
        print("[\(Date())] Speech resumed: \(utterance.speechString)")
    }
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        print("[\(Date())] Speech cancelled: \(utterance.speechString)")
    }
}
