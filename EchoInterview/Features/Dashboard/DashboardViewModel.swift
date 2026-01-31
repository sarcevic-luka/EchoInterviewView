import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    private let router: Router
    private let serviceContainer: ServiceContainer
    
    private(set) var isCheckingPermissions = false
    private(set) var hasMicPermission = false
    private(set) var hasSpeechPermission = false
    var permissionError: String?
    
    init(router: Router, serviceContainer: ServiceContainer = .shared) {
        self.router = router
        self.serviceContainer = serviceContainer
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
}
