import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(Router.self) private var router
    @Environment(\.serviceContainer) private var serviceContainer
    @Environment(\.modelContext) private var modelContext
    
    private var persistenceService: PersistenceService {
        PersistenceService(modelContainer: modelContext.container)
    }
    
    var body: some View {
        NavigationStack(path: Bindable(router).path) {
            DashboardView(viewModel: makeDashboardViewModel())
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .dashboard:
            DashboardView(viewModel: makeDashboardViewModel())
        case .onboarding:
            OnboardingView(onComplete: {
                router.navigateToRoot()
            })
        case .sessionSetup:
            Text("Session Setup")
        case .interviewRoom, .interviewSession:
            InterviewRoomView(viewModel: makeInterviewViewModel())
        case .analytics:
            Text("Analytics")
        case .history:
            HistoryView(viewModel: HistoryViewModel(persistenceService: persistenceService))
        case .settings:
            SettingsView(viewModel: SettingsViewModel(
                persistenceService: persistenceService,
                audioService: serviceContainer.audioService,
                speechService: serviceContainer.speechService
            ))
        case .audioTest:
            AudioTestView()
        }
    }
    
    private func makeDashboardViewModel() -> DashboardViewModel {
        let viewModel = DashboardViewModel(
            router: router,
            serviceContainer: serviceContainer,
            persistenceService: persistenceService
        )
        return viewModel
    }
    
    private func makeInterviewViewModel() -> InterviewSessionViewModel {
        InterviewSessionViewModel(
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
        .modelContainer(try! ModelContainer(for: InterviewSessionEntity.self))
}
