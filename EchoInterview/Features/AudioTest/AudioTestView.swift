import SwiftUI

struct AudioTestView: View {
    @State private var permissionStatus: String = "Not requested"
    @State private var speechPermissionStatus: String = "Not requested"
    @State private var isRecording = false
    @State private var transcript: String = ""
    @State private var isSpeaking = false
    @State private var recordingTask: Task<Void, Never>?
    
    private let audioService: any AudioService
    private let speechService: any SpeechRecognitionService
    private let ttsService: any TextToSpeechService
    
    init(
        audioService: any AudioService = AudioServiceImpl(),
        speechService: any SpeechRecognitionService = SpeechRecognitionServiceImpl(),
        ttsService: any TextToSpeechService = TextToSpeechServiceImpl()
    ) {
        self.audioService = audioService
        self.speechService = speechService
        self.ttsService = ttsService
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                permissionsSection
                recordingSection
                transcriptSection
                ttsSection
            }
            .padding()
        }
        .navigationTitle("Audio Test")
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        VStack(spacing: 16) {
            Text("Permissions")
                .font(.headline)
            
            HStack {
                Text("Microphone:")
                Spacer()
                Text(permissionStatus)
                    .foregroundStyle(statusColor(for: permissionStatus))
            }
            
            HStack {
                Text("Speech Recognition:")
                Spacer()
                Text(speechPermissionStatus)
                    .foregroundStyle(statusColor(for: speechPermissionStatus))
            }
            
            Button("Request All Permissions") {
                requestAllPermissions()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Recording Section
    
    private var recordingSection: some View {
        VStack(spacing: 16) {
            Text("Recording")
                .font(.headline)
            
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                    Text(isRecording ? "Stop Recording" : "Start Recording (5s)")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(isRecording ? .red : .blue)
            
            if isRecording {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Transcript Section
    
    private var transcriptSection: some View {
        VStack(spacing: 16) {
            Text("Transcript")
                .font(.headline)
            
            Text(transcript.isEmpty ? "No transcript yet..." : transcript)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - TTS Section
    
    private var ttsSection: some View {
        VStack(spacing: 16) {
            Text("Text-to-Speech")
                .font(.headline)
            
            Button {
                speakTranscript()
            } label: {
                HStack {
                    Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    Text(isSpeaking ? "Speaking..." : "Speak Transcript")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(transcript.isEmpty || isSpeaking)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helpers
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Granted": return .green
        case "Denied": return .red
        default: return .secondary
        }
    }
    
    // MARK: - Actions
    
    private func requestAllPermissions() {
        Task {
            async let micGranted = audioService.requestMicrophonePermission()
            async let speechGranted = speechService.requestAuthorization()
            
            let (mic, speech) = await (micGranted, speechGranted)
            
            await MainActor.run {
                permissionStatus = mic ? "Granted" : "Denied"
                speechPermissionStatus = speech ? "Granted" : "Denied"
            }
        }
    }
    
    private func startRecording() {
        isRecording = true
        transcript = ""
        
        recordingTask = Task {
            do {
                let audioStream = try await audioService.startRecording()
                let transcriptStream = try await speechService.startRecognition(audioStream: audioStream)
                
                // Auto-stop after 5 seconds
                Task {
                    try? await Task.sleep(for: .seconds(5))
                    if !Task.isCancelled {
                        await MainActor.run {
                            stopRecording()
                        }
                    }
                }
                
                for await partialTranscript in transcriptStream {
                    guard !Task.isCancelled else { break }
                    await MainActor.run {
                        transcript = partialTranscript
                    }
                }
            } catch {
                await MainActor.run {
                    transcript = "Error: \(error.localizedDescription)"
                    isRecording = false
                }
            }
        }
    }
    
    private func stopRecording() {
        recordingTask?.cancel()
        recordingTask = nil
        
        Task {
            await audioService.stopRecording()
            let finalTranscript = await speechService.stopRecognition()
            
            await MainActor.run {
                if !finalTranscript.isEmpty {
                    transcript = finalTranscript
                }
                isRecording = false
            }
        }
    }
    
    private func speakTranscript() {
        guard !transcript.isEmpty else { return }
        
        isSpeaking = true
        Task {
            do {
                try await ttsService.speak(transcript)
            } catch {
                // Speech was cancelled or failed
            }
            await MainActor.run {
                isSpeaking = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        AudioTestView()
    }
}
