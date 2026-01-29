import Foundation

@Observable
@MainActor
final class AppState {
    var isFirstLaunch: Bool = true
    
    init() {}
}

