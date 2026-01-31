import SwiftUI

struct ContentView: View {
    @Environment(Router.self) private var router
    @Environment(\.serviceContainer) private var serviceContainer
    
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
            InterviewRoomView(viewModel: InterviewSessionViewModel(
                audioService: serviceContainer.audioService,
                speechService: serviceContainer.speechService,
                ttsService: serviceContainer.ttsService,
                nlpService: serviceContainer.nlpService,
                scoringService: serviceContainer.scoringService
            ))
        case .analytics:
            Text("Analytics")
        case .history:
            Text("History")
        case .settings:
            Text("Settings")
        case .audioTest:
            AudioTestView()
        case .interviewSession:
            InterviewRoomView(viewModel: InterviewSessionViewModel(
                audioService: serviceContainer.audioService,
                speechService: serviceContainer.speechService,
                ttsService: serviceContainer.ttsService,
                nlpService: serviceContainer.nlpService,
                scoringService: serviceContainer.scoringService
            ))
        }
    }
}

#Preview {
    ContentView()
        .environment(Router())
        .environment(AppState())
        .environment(\.serviceContainer, .shared)
}
