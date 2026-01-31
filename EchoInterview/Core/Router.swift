import SwiftUI

enum Route: Hashable {
    case dashboard
    case onboarding
    case sessionSetup
    case interviewRoom
    case analytics
    case history
    case settings
    case audioTest
}

@Observable
final class Router {
    var path = NavigationPath()
    
    init() {}
    
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func navigateBack() {
        path.removeLast()
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
}

