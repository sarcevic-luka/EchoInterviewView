import SwiftUI

@main
struct EchoInterviewApp: App {
    @State private var router = Router()
    @State private var appState = AppState()
    private let serviceContainer = ServiceContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .environment(appState)
                .environment(\.serviceContainer, serviceContainer)
        }
    }
}
