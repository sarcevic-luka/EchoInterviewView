import SwiftUI

final class ServiceContainer: @unchecked Sendable {
    static let shared = ServiceContainer()
    
    let audioService: any AudioService
    let speechService: any SpeechRecognitionService
    let ttsService: any TextToSpeechService
    let nlpService: NLPAnalysisService
    let scoringService: SimpleScoringService
    
    private init() {
        self.audioService = AudioServiceImpl()
        self.speechService = SpeechRecognitionServiceImpl()
        self.ttsService = TextToSpeechServiceImpl()
        self.nlpService = NLPAnalysisService()
        self.scoringService = SimpleScoringService()
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
