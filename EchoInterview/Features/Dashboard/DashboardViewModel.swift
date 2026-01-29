import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    private let router: Router
    
    init(router: Router) {
        self.router = router
    }
}

