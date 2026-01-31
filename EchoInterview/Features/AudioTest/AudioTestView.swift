import SwiftUI

struct AudioTestView: View {
    @State private var permissionStatus: String = "Not requested"
    @State private var speechPermissionStatus: String = "Not requested"
    @State private var isRecording = false
    @State private var transcript: String = ""
    @State private var isSpeaking = false
    @State private var recordingTask: Task<Void, Never>?
    @State private var recordingStartTime: Date?
    @State private var metrics: NLPMetrics?
    
    private let audioService: any AudioService
    private let speechService: any SpeechRecognitionService
    private let ttsService: any TextToSpeechService
    private let nlpService: NLPAnalysisService
    
    init(
        audioService: any AudioService = AudioServiceImpl(),
        speechService: any SpeechRecognitionService = SpeechRecognitionServiceImpl(),
        ttsService: any TextToSpeechService = TextToSpeechServiceImpl(),
        nlpService: NLPAnalysisService = NLPAnalysisService()
    ) {
        self.audioService = audioService
        self.speechService = speechService
        self.ttsService = ttsService
        self.nlpService = nlpService
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                permissionsSection
                recordingSection
                transcriptSection
                metricsSection
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
    
    // MARK: - Metrics Section
    
    private var metricsSection: some View {
        VStack(spacing: 16) {
            Text("NLP Metrics")
                .font(.headline)
            
            if let metrics {
                VStack(spacing: 12) {
                    MetricRow(label: "Total Words", value: "\(metrics.totalWordCount)")
                    MetricRow(label: "Filler Words", value: "\(metrics.fillerWordCount)")
                    MetricRow(label: "Speech Rate", value: String(format: "%.1f wpm", metrics.speechRate))
                    
                    if metrics.totalWordCount > 0 {
                        let fillerPercentage = Double(metrics.fillerWordCount) / Double(metrics.totalWordCount) * 100
                        MetricRow(label: "Filler %", value: String(format: "%.1f%%", fillerPercentage))
                    }
                }
            } else {
                Text("Record audio to see metrics...")
                    .foregroundStyle(.secondary)
            }
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
        metrics = nil
        recordingStartTime = Date()
        
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
        
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        Task {
            await audioService.stopRecording()
            let finalTranscript = await speechService.stopRecognition()
            
            await MainActor.run {
                if !finalTranscript.isEmpty {
                    transcript = finalTranscript
                }
                
                if !transcript.isEmpty {
                    metrics = nlpService.analyze(transcript: transcript, duration: duration)
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

// MARK: - Metric Row

private struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        AudioTestView()
    }
}
