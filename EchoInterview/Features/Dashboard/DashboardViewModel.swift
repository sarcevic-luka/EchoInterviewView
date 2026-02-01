import Foundation
import os.log

@Observable
@MainActor
final class DashboardViewModel {
    private let router: Router
    private let serviceContainer: ServiceContainer
    private var persistenceService: PersistenceService?
    private let logger = Logger(subsystem: "EchoInterview", category: "DashboardViewModel")
    
    private(set) var isCheckingPermissions = false
    private(set) var hasMicPermission = false
    private(set) var hasSpeechPermission = false
    private(set) var recentSessions: [InterviewSessionEntity] = []
    private(set) var isLoadingSessions = false
    var permissionError: String?
    
    init(router: Router, serviceContainer: ServiceContainer = .shared, persistenceService: PersistenceService? = nil) {
        self.router = router
        self.serviceContainer = serviceContainer
        self.persistenceService = persistenceService
    }
    
    func setPersistenceService(_ service: PersistenceService) {
        self.persistenceService = service
    }
    
    func checkPermissions() async {
        isCheckingPermissions = true
        defer { isCheckingPermissions = false }
        
        async let micPermission = serviceContainer.audioService.requestMicrophonePermission()
        async let speechPermission = serviceContainer.speechService.requestAuthorization()
        
        let (mic, speech) = await (micPermission, speechPermission)
        hasMicPermission = mic
        hasSpeechPermission = speech
    }
    
    func loadRecentSessions() async {
        guard let persistenceService else {
            logger.debug("No persistence service available")
            return
        }
        
        isLoadingSessions = true
        defer { isLoadingSessions = false }
        
        do {
            let allSessions = try await persistenceService.fetchAllSessions()
            recentSessions = Array(allSessions.prefix(3))
            logger.debug("Loaded \(self.recentSessions.count) recent sessions")
        } catch {
            logger.error("Failed to load recent sessions: \(error.localizedDescription)")
        }
    }
    
    func startInterview() async {
        permissionError = nil
        
        // Check permissions first
        if !hasMicPermission {
            let granted = await serviceContainer.audioService.requestMicrophonePermission()
            hasMicPermission = granted
            if !granted {
                permissionError = "Microphone access is required to record your interview answers. Please enable it in Settings."
                return
            }
        }
        
        if !hasSpeechPermission {
            let granted = await serviceContainer.speechService.requestAuthorization()
            hasSpeechPermission = granted
            if !granted {
                permissionError = "Speech recognition is required to transcribe your answers. Please enable it in Settings."
                return
            }
        }
        
        // All permissions granted, navigate to interview
        router.navigate(to: .interviewSession)
    }
    
    func navigateToAudioTest() {
        router.navigate(to: .audioTest)
    }
    
    func navigateToInterviewSession() {
        router.navigate(to: .interviewSession)
    }
    
    func navigateToHistory() {
        router.navigate(to: .history)
    }
    
    func navigateToSettings() {
        router.navigate(to: .settings)
    }
}
