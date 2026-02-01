import Foundation
import os.log

enum SessionState: Equatable {
    case idle
    case listening
    case speaking(transcript: String)
    case analyzing
    case showingResults
    case error(message: String)
}

@MainActor
@Observable
final class InterviewSessionViewModel {
    private let audioService: any AudioService
    private let speechService: any SpeechRecognitionService
    private let ttsService: any TextToSpeechService
    private let nlpService: NLPAnalysisService
    private let scoringService: any ScoringProtocol
    private let llmService: LLMServiceProtocol
    private let persistenceService: PersistenceService?
    private let logger = Logger(subsystem: "EchoInterview", category: "InterviewSession")
    
    private(set) var currentState: SessionState = .idle
    private(set) var currentQuestionIndex: Int = 0
    private(set) var answers: [Answer] = []
    private(set) var questions: [Question] = []
    private(set) var currentTips: [String] = []
    private(set) var isSessionSaved: Bool = false
    var errorMessage: String?
    
    private var recordingStartTime: Date?
    private var recordingTask: Task<Void, Never>?
    private var currentTranscript: String = ""
    
    let interviewType: String
    let totalQuestions: Int
    
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex >= totalQuestions - 1
    }
    
    var progress: Double {
        Double(currentQuestionIndex + 1) / Double(totalQuestions)
    }
    
    init(
        audioService: any AudioService = AudioServiceImpl(),
        speechService: any SpeechRecognitionService = SpeechRecognitionServiceImpl(),
        ttsService: any TextToSpeechService = TextToSpeechServiceImpl(),
        nlpService: NLPAnalysisService = NLPAnalysisService(),
        scoringService: any ScoringProtocol = SimpleScoringService(),
        llmService: LLMServiceProtocol = LLMService(),
        persistenceService: PersistenceService? = nil,
        interviewType: String = "Software Engineering",
        totalQuestions: Int = 5
    ) {
        self.audioService = audioService
        self.speechService = speechService
        self.ttsService = ttsService
        self.nlpService = nlpService
        self.scoringService = scoringService
        self.llmService = llmService
        self.persistenceService = persistenceService
        self.interviewType = interviewType
        self.totalQuestions = totalQuestions
    }
    
    // MARK: - State Machine Methods
    
    func beginInterview() {
        currentQuestionIndex = 0
        answers = []
        questions = []
        currentTips = []
        
        Task {
            await generateAndSpeakNextQuestion()
        }
    }
    
    func startListening() {
        currentState = .speaking(transcript: "")
        currentTranscript = ""
        recordingStartTime = Date()
        errorMessage = nil
        
        recordingTask = Task {
            // Stop any ongoing TTS first so it doesn't interfere with recording
            await ttsService.stop()
            
            do {
                let audioStream = try await audioService.startRecording()
                let transcriptStream = try await speechService.startRecognition(audioStream: audioStream)
                
                for await partialTranscript in transcriptStream {
                    currentTranscript = partialTranscript
                    currentState = .speaking(transcript: partialTranscript)
                }
            } catch {
                errorMessage = "Recording failed: \(error.localizedDescription)"
                currentState = .listening
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
            
            let scores: AnswerScores
            do {
                scores = try scoringService.calculateScores(metrics: metrics, transcript: transcript)
            } catch {
                let logger = Logger(subsystem: "EchoInterview", category: "InterviewSession")
                logger.error("Scoring failed: \(error.localizedDescription)")
                errorMessage = "Failed to calculate scores: \(error.localizedDescription)"
                currentState = .showingResults
                return
            }
            
            let answer = Answer(
                transcript: transcript,
                duration: duration,
                metrics: metrics,
                scores: scores
            )
            
            answers.append(answer)
            
            // Generate contextual feedback tips
            let tips = await llmService.generateFeedback(answer: answer)
            currentTips = tips
            
            currentState = .showingResults
        }
    }
    
    func nextQuestion() {
        guard currentQuestionIndex < totalQuestions - 1 else {
            return
        }
        
        currentQuestionIndex += 1
        currentTips = []
        
        Task {
            await generateAndSpeakNextQuestion()
        }
    }
    
    func resetInterview() {
        recordingTask?.cancel()
        recordingTask = nil
        currentState = .idle
        currentQuestionIndex = 0
        answers = []
        questions = []
        currentTips = []
        currentTranscript = ""
        errorMessage = nil
        isSessionSaved = false
    }
    
    func dismissError() {
        errorMessage = nil
    }
    
    func completeInterview() async {
        guard !answers.isEmpty, !isSessionSaved else { return }
        
        guard let persistenceService else {
            logger.warning("No persistence service available, session not saved")
            return
        }
        
        guard let entity = InterviewSessionEntity.from(answers: answers, interviewType: interviewType) else {
            logger.error("Failed to create session entity")
            return
        }
        
        do {
            try await persistenceService.saveSession(entity)
            isSessionSaved = true
            logger.info("Interview session saved successfully")
        } catch {
            logger.error("Failed to save session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    private func generateAndSpeakNextQuestion() async {
        currentState = .listening
        
        // Generate question using LLM with context of previous questions
        let questionText = await llmService.generateQuestion(
            context: questions,
            interviewType: interviewType
        )
        
        let question = Question(text: questionText)
        questions.append(question)
        
        // Speak the generated question
        do {
            try await ttsService.speak(questionText)
        } catch {
            // TTS failed, continue anyway - user can still see the question
        }
    }
    
    private func speakCurrentQuestion() {
        guard let question = currentQuestion else { return }
        
        currentState = .listening
        
        Task {
            do {
                try await ttsService.speak(question.text)
            } catch {
                // TTS failed, continue anyway
            }
        }
    }
}
