//
//  ContentView.swift
//  localVoiceAI
//
//  Created by Skryang on 2025/5/26.
//

import SwiftUI

struct ContentView: View {
    // AI Conversation Manager
    @StateObject private var chatManager = AIConversationManager()
    @State private var inputText = ""
    
    // Audio and Speech Managers
    @StateObject private var speechManager = SpeechManager()
    @State private var isRecording = false
    
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(chatManager.messages) { msg in
                        HStack {
                            if msg.role == "user" {
                                Spacer()
                                Text(msg.content)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(10)
                                Image("people", bundle: nil)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .padding(.trailing, 12)
                            } else {
                                Image("ai", bundle: nil)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .padding(.trailing, 12)
                                Text(msg.content)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("请询问你的问题", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    Task {
                        await chatManager.setMessage(text)
                        inputText = ""
                    }
                }) {
                    Text("发送")
                }
                
                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        speechManager.startRecording()
                    } else {
                        speechManager.stopRecording()
                        inputText = speechManager.transcribedText
                        
                        Task {
                            await chatManager.setMessage(inputText)
                            chatManager.latestResponseBlock = { response in
                                SpeechSynthesizer.shared.speak(response)
                            }
                        }
                        
                    }
                }) {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
