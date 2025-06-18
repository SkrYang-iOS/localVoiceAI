//
//  SpeechSynthesizer.swift
//  localVoiceAI
//
//  Created by Skryang on 2025/6/5.
//

import Foundation
import AVFoundation

enum VoiceProfile: String, CaseIterable {
    case female = "Ting-Ting"   // 中文女声（默认）
    case male = "Liang"         // 中文男声
    case siri = "Siri"          // 系统 Siri 声音（需系统支持）

    var avVoice: AVSpeechSynthesisVoice? {
        switch self {
        case .female:
            return AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Ting-Ting-compact")
        case .male:
            return AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Liang-compact")
        case .siri:
            return AVSpeechSynthesisVoice(language: "zh-CN") // fallback if Siri not exposed
        }
    }
}

class SpeechSynthesizer {
    static let shared = SpeechSynthesizer()
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var currentVoice: VoiceProfile = .siri
    @Published var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    @Published var pitchMultiplier: Float = 1.0

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = currentVoice.avVoice ?? AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = speechRate
        utterance.pitchMultiplier = pitchMultiplier
        synthesizer.speak(utterance)
    }
}
