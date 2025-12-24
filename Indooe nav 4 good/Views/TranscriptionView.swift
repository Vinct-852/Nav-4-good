import SwiftUI
import Speech
import AVFoundation

struct TranscriptionView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var classifiedResult: IntentRouter.IntentResult? = nil
    @State private var silenceTimer: Timer? = nil
    
    private let intentRouter = IntentRouter()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status indicator
                HStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.gray)
                        .frame(width: 12, height: 12)
                    Text(isRecording ? "錄音中..." : "未錄音")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Transcription display
                ScrollView {
                    Text(speechRecognizer.transcript.isEmpty ? "按下方按鈕開始錄音..." : speechRecognizer.transcript)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Intent classification result
                VStack(alignment: .leading, spacing: 12) {

                    if let result = classifiedResult {
                
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("意圖:")
                                    .fontWeight(.medium)
                                Text(result.intent.rawValue.capitalized)
                                    .foregroundColor(.blue)
                            }

                            HStack {
                                Text("置信度:")
                                    .fontWeight(.medium)
                                Text(String(format: "%.2f", result.confidence))
                                    .foregroundColor(.green)
                            }

                            HStack(alignment: .top) {
                                Text("參數:")
                                    .fontWeight(.medium)
                                Text(String(describing: result.parameters))
                                    .foregroundColor(.purple)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        intentRouter.handleIntentResult(result)

                    } else {
                        Text("尚未分類")
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                
                // Control button
                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title)
                        Text(isRecording ? "停止錄音" : "開始錄音")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isRecording ? Color.red : Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Button(action: testIntentRouter){
                    Text("Intent Router Test").font(.headline)
                }
                
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: speechRecognizer.transcript) { newTranscript in
            guard !newTranscript.isEmpty else { return }
            handleTranscriptChange()
        }
    }
    
    private func handleTranscriptChange() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            processFinalTranscript()
        }
    }

    private func processFinalTranscript() {
        guard !speechRecognizer.transcript.isEmpty else { return }
        Task {
            let result = await intentRouter.classifyIntent(from: speechRecognizer.transcript)
            classifiedResult = result
        }
    }

    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopTranscribing()
            isRecording = false
            processFinalTranscript()
        } else {
            speechRecognizer.transcribe()
            isRecording = true
        }
    }
    
    private func testIntentRouter() {
        let testString = "最近嘅washroom喺邊度"
        Task {
            let result = await intentRouter.classifyIntent(from: testString)
            classifiedResult = result
        }
    }
}
