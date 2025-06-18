//
//  SpeechManager.swift
//  localVoiceAI
//
//  Created by Skryang on 2025/6/5.
//

import Foundation
import Speech
import AVFoundation

class SpeechManager: ObservableObject {
    private let recongnizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var transcribedText: String = ""
    
    func startRecording() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            guard authStatus == .authorized else {
                print("Speech recognition authorization denied")
                return
            }
            
            DispatchQueue.main.async {
                self.transcribedText = ""
                self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = self.recognitionRequest else { return }
                
                let inputNode = self.audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                    recognitionRequest.append(buffer)
                }
                
                self.audioEngine.prepare()
                try? self.audioEngine.start()
                
                self.recognitionTask = self.recongnizer?.recognitionTask(with: recognitionRequest) { result, error in
                    if let result = result {
                        self.transcribedText = result.bestTranscription.formattedString
                    }
                    
                    if error != nil || (result?.isFinal ?? false) {
                        self.stopRecording()
                    }
                }
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
