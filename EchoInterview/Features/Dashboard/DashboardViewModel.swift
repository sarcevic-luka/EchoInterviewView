import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
    
    func navigateToAudioTest() {
        router.navigate(to: .audioTest)
    }
    
    func navigateToInterviewSession() {
        router.navigate(to: .interviewSession)
    }
}

