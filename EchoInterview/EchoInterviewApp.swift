import SwiftUI

@main
struct EchoInterviewApp: App {
    @State private var router = Router()
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .environment(appState)
        }
    }
}
