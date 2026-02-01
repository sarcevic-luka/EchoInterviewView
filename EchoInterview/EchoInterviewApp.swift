import SwiftUI
import SwiftData

@main
struct EchoInterviewApp: App {
    @State private var router = Router()
    @State private var appState = AppState()
    private let serviceContainer = ServiceContainer.shared
    
    let modelContainer: ModelContainer
    
    init() {
        // Ensure Application Support directory exists to avoid CoreData warnings on first launch
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            if !fileManager.fileExists(atPath: appSupportURL.path) {
                try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }
        }
        
        do {
            modelContainer = try ModelContainer(for: InterviewSessionEntity.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView {
                        appState.completeOnboarding()
                    }
                }
            }
            .environment(router)
            .environment(appState)
            .environment(\.serviceContainer, serviceContainer)
            .modelContainer(modelContainer)
        }
    }
}
