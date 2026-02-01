import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(Router.self) private var router
    @Environment(\.serviceContainer) private var serviceContainer
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack(path: Bindable(router).path) {
            DashboardView(viewModel: DashboardViewModel(
                router: router,
                serviceContainer: serviceContainer
            ))
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .dashboard:
            DashboardView(viewModel: DashboardViewModel(
                router: router,
                serviceContainer: serviceContainer
            ))
        case .onboarding:
            Text("Onboarding")
        case .sessionSetup:
            Text("Session Setup")
        case .interviewRoom:
            InterviewRoomView(viewModel: makeInterviewViewModel())
        case .analytics:
            Text("Analytics")
        case .history:
            Text("History")
        case .settings:
            Text("Settings")
        case .audioTest:
            AudioTestView()
        case .interviewSession:
            InterviewRoomView(viewModel: makeInterviewViewModel())
        }
    }
    
    private func makeInterviewViewModel() -> InterviewSessionViewModel {
        let persistenceService = PersistenceService(modelContainer: modelContext.container)
        return InterviewSessionViewModel(
            audioService: serviceContainer.audioService,
            speechService: serviceContainer.speechService,
            ttsService: serviceContainer.ttsService,
            nlpService: serviceContainer.nlpService,
            scoringService: serviceContainer.scoringService,
            llmService: serviceContainer.llmService,
            persistenceService: persistenceService
        )
    }
}

#Preview {
    ContentView()
        .environment(Router())
        .environment(AppState())
        .environment(\.serviceContainer, .shared)
}
