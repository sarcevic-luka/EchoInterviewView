import SwiftUI
import os.log

struct AudioTestView: View {
    @State private var permissionStatus: String = "Not requested"
    @State private var speechPermissionStatus: String = "Not requested"
    @State private var isRecording = false
    @State private var transcript: String = ""
    @State private var isSpeaking = false
    @State private var recordingTask: Task<Void, Never>?
    @State private var recordingStartTime: Date?
    @State private var metrics: NLPMetrics?
    @State private var scores: AnswerScores?
    @State private var scoringError: String?
    
    private let logger = Logger(subsystem: "EchoInterview", category: "AudioTestView")
    
    private let audioService: any AudioService
    private let speechService: any SpeechRecognitionService
    private let ttsService: any TextToSpeechService
    private let nlpService: NLPAnalysisService
    private let scoringService: any ScoringProtocol
    
    private var allPermissionsGranted: Bool {
        permissionStatus == "Granted" && speechPermissionStatus == "Granted"
    }
    
    init(
        audioService: any AudioService = AudioServiceImpl(),
        speechService: any SpeechRecognitionService = SpeechRecognitionServiceImpl(),
        ttsService: any TextToSpeechService = TextToSpeechServiceImpl(),
        nlpService: NLPAnalysisService = NLPAnalysisService(),
        scoringService: any ScoringProtocol = SimpleScoringService()
    ) {
        self.audioService = audioService
        self.speechService = speechService
        self.ttsService = ttsService
        self.nlpService = nlpService
        self.scoringService = scoringService
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !allPermissionsGranted {
                    permissionsSection
                }
                recordingSection
                transcriptSection
                metricsSection
                scoresSection
                ttsSection
            }
            .padding()
        }
        .navigationTitle("Audio Test")
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity)
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
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRecording ? .red : .blue)
            
            if isRecording {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Transcript Section
    
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transcript")
                .font(.headline)
            
            Text(transcript.isEmpty ? "No transcript yet..." : transcript)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Metrics Section
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("NLP Metrics")
                .font(.headline)
            
            if let metrics {
                VStack(spacing: 12) {
                    MetricRow(label: "Total Words", value: "\(metrics.totalWordCount)")
                    MetricRow(label: "Sentences", value: "\(metrics.sentenceCount)")
                    MetricRow(label: "Avg Sentence Length", value: String(format: "%.1f words", metrics.avgSentenceLength))
                    MetricRow(label: "Speech Rate", value: String(format: "%.1f wpm", metrics.speechRate))
                    
                    Divider()
                    
                    MetricRow(label: "Filler Words", value: "\(metrics.fillerWordCount)")
                    MetricRow(label: "Filler Ratio", value: String(format: "%.1f%%", metrics.fillerRatio * 100))
                    MetricRow(label: "Pause Count", value: "\(metrics.pauseCount)")
                    
                    Divider()
                    
                    MetricProgressRow(
                        label: "Keyword Coverage",
                        value: metrics.keywordCoverage,
                        color: coverageColor(for: metrics.keywordCoverage)
                    )
                    
                    MetricProgressRow(
                        label: "Semantic Similarity",
                        value: metrics.semanticSimilarity,
                        color: similarityColor(for: metrics.semanticSimilarity)
                    )
                }
            } else {
                Text("Record audio to see metrics...")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func similarityColor(for similarity: Double) -> Color {
        if similarity >= 0.7 { return .green }
        if similarity >= 0.5 { return .orange }
        return .red
    }
    
    private func coverageColor(for coverage: Double) -> Color {
        if coverage >= 0.6 { return .green }
        if coverage >= 0.3 { return .orange }
        return .red
    }
    
    // MARK: - Scores Section
    
    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Answer Scores")
                .font(.headline)
            
            if let scores {
                VStack(spacing: 12) {
                    ScoreRow(label: "Overall", score: scores.overall)
                    ScoreRow(label: "Clarity", score: scores.clarity)
                    ScoreRow(label: "Confidence", score: scores.confidence)
                    ScoreRow(label: "Technical", score: scores.technical)
                    ScoreRow(label: "Pace", score: scores.pace)
                }
            } else if let scoringError {
                VStack(spacing: 8) {
                    Label("Scoring Error", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(scoringError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("Record audio to see scores...")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
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
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(transcript.isEmpty || isSpeaking)
        }
        .padding()
        .frame(maxWidth: .infinity)
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
        scores = nil
        recordingStartTime = Date()
        
        recordingTask = Task {
            do {
                let audioStream = try await audioService.startRecording()
                let transcriptStream = try await speechService.startRecognition(audioStream: audioStream)
                
                // Auto-stop after 30 seconds
                Task {
                    try? await Task.sleep(for: .seconds(30))
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
                    let analyzedMetrics = nlpService.analyze(transcript: transcript, duration: duration)
                    metrics = analyzedMetrics
                    
                    do {
                        scores = try scoringService.calculateScores(metrics: analyzedMetrics, transcript: transcript)
                        scoringError = nil
                    } catch {
                        logger.error("Scoring failed: \(error.localizedDescription)")
                        scoringError = error.localizedDescription
                        scores = nil
                    }
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

// MARK: - Metric Progress Row

private struct MetricProgressRow: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", value * 100))
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }
            
            ProgressView(value: value)
                .progressViewStyle(.linear)
                .tint(color)
        }
    }
}

// MARK: - Score Row

private struct ScoreRow: View {
    let label: String
    let score: Double
    
    private var scoreColor: Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.0f", score))
                .fontWeight(.bold)
                .foregroundStyle(scoreColor)
            
            ProgressView(value: score, total: 100)
                .progressViewStyle(.linear)
                .frame(width: 60)
                .tint(scoreColor)
        }
    }
}

#Preview {
    NavigationStack {
        AudioTestView()
    }
}
