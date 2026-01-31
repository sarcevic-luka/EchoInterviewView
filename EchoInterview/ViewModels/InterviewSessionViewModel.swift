import Foundation

enum SessionState: Equatable {
    case idle
    case listening
    case speaking(transcript: String)
    case analyzing
    case showingResults
}

@MainActor
@Observable
final class InterviewSessionViewModel {
    private let audioService: any AudioService
    private let speechService: any SpeechRecognitionService
    private let ttsService: any TextToSpeechService
    private let nlpService: NLPAnalysisService
    private let scoringService: SimpleScoringService
    
    private(set) var currentState: SessionState = .idle
    private(set) var currentQuestionIndex: Int = 0
    private(set) var answers: [Answer] = []
    
    private var recordingStartTime: Date?
    private var recordingTask: Task<Void, Never>?
    private var currentTranscript: String = ""
    
    let questions: [Question] = [
        Question(text: "Tell me about a recent project you're proud of."),
        Question(text: "Describe a technical challenge you faced and how you solved it."),
        Question(text: "How do you prioritize tasks when working on multiple projects?"),
        Question(text: "Tell me about a time you had to learn a new technology quickly."),
        Question(text: "Where do you see yourself in your career in 3 years?")
    ]
    
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex >= questions.count - 1
    }
    
    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    init(
        audioService: any AudioService = AudioServiceImpl(),
        speechService: any SpeechRecognitionService = SpeechRecognitionServiceImpl(),
        ttsService: any TextToSpeechService = TextToSpeechServiceImpl(),
        nlpService: NLPAnalysisService = NLPAnalysisService(),
        scoringService: SimpleScoringService = SimpleScoringService()
    ) {
        self.audioService = audioService
        self.speechService = speechService
        self.ttsService = ttsService
        self.nlpService = nlpService
        self.scoringService = scoringService
    }
    
    // MARK: - State Machine Methods
    
    func beginInterview() {
        currentQuestionIndex = 0
        answers = []
        speakCurrentQuestion()
    }
    
    func startListening() {
        currentState = .speaking(transcript: "")
        currentTranscript = ""
        recordingStartTime = Date()
        
        recordingTask = Task {
            do {
                let audioStream = try await audioService.startRecording()
                let transcriptStream = try await speechService.startRecognition(audioStream: audioStream)
                
                for await partialTranscript in transcriptStream {
                    guard !Task.isCancelled else { break }
                    currentTranscript = partialTranscript
                    currentState = .speaking(transcript: partialTranscript)
                }
            } catch {
                currentState = .speaking(transcript: "Error: \(error.localizedDescription)")
            }
        }
    }
    
    func analyzeAnswer() {
        recordingTask?.cancel()
        recordingTask = nil
        currentState = .analyzing
        
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        Task {
            await audioService.stopRecording()
            let finalTranscript = await speechService.stopRecognition()
            
            let transcript = finalTranscript.isEmpty ? currentTranscript : finalTranscript
            
            guard !transcript.isEmpty else {
                currentState = .showingResults
                return
            }
            
            let metrics = nlpService.analyze(transcript: transcript, duration: duration)
            let scores = scoringService.calculateScores(metrics: metrics)
            
            let answer = Answer(
                transcript: transcript,
                duration: duration,
                metrics: metrics,
                scores: scores
            )
            
            answers.append(answer)
            currentState = .showingResults
        }
    }
    
    func nextQuestion() {
        guard currentQuestionIndex < questions.count - 1 else {
            return
        }
        
        currentQuestionIndex += 1
        speakCurrentQuestion()
    }
    
    func resetInterview() {
        recordingTask?.cancel()
        recordingTask = nil
        currentState = .idle
        currentQuestionIndex = 0
        answers = []
        currentTranscript = ""
    }
    
    // MARK: - Private Methods
    
    private func speakCurrentQuestion() {
        guard let question = currentQuestion else { return }
        
        currentState = .listening
        
        Task {
            do {
                try await ttsService.speak(question.text)
            } catch {
                // TTS failed, continue anyway
            }
            // After speaking, stay in listening state waiting for user to tap
        }
    }
}
