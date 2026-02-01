import Foundation

@Observable
@MainActor
final class AppState {
    private(set) var hasCompletedOnboarding: Bool
    
    private enum UserDefaultsKeys {
        static let firstLaunchComplete = "firstLaunchComplete"
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: UserDefaultsKeys.firstLaunchComplete)
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.firstLaunchComplete)
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.firstLaunchComplete)
        hasCompletedOnboarding = false
    }
}

