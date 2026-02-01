import SwiftUI
import os.log

final class ServiceContainer: @unchecked Sendable {
    static let shared = ServiceContainer()
    
    let audioService: any AudioService
    let speechService: any SpeechRecognitionService
    let ttsService: any TextToSpeechService
    let nlpService: NLPAnalysisService
    let scoringService: any ScoringProtocol
    let isUsingCoreML: Bool
    
    private static let logger = Logger(subsystem: "EchoInterview", category: "ServiceContainer")
    
    private init() {
        self.audioService = AudioServiceImpl()
        self.speechService = SpeechRecognitionServiceImpl()
        self.ttsService = TextToSpeechServiceImpl()
        self.nlpService = NLPAnalysisService()
        
        // Try CoreML scoring, fallback to simple scoring
        if let mlService = try? CoreMLScoringService() {
            self.scoringService = mlService
            self.isUsingCoreML = true
            Self.logger.info("Using CoreML scoring service")
        } else {
            self.scoringService = SimpleScoringService()
            self.isUsingCoreML = false
            Self.logger.info("Using simple scoring service (CoreML not available)")
        }
    }
}

// MARK: - Environment Key

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = .shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
