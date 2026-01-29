import Foundation

enum InterviewState {
    case idle
    case aiThinking
    case aiSpeaking
    case listening
    case speaking
    case analyzing
    case providingFeedback
    case transitioning
    case complete
}

@Observable
@MainActor
final class InterviewViewModel {
    var state: InterviewState = .idle
    
    private let router: Router
    private let speechService: SpeechServiceProtocol
    private let analysisService: AnalysisServiceProtocol
    
    init(
        router: Router,
        speechService: SpeechServiceProtocol,
        analysisService: AnalysisServiceProtocol
    ) {
        self.router = router
        self.speechService = speechService
        self.analysisService = analysisService
    }
}

