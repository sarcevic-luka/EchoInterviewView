import SwiftUI

struct ContentView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        NavigationStack(path: Bindable(router).path) {
            DashboardView(viewModel: DashboardViewModel(router: router))
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .dashboard:
            DashboardView(viewModel: DashboardViewModel(router: router))
        case .onboarding:
            Text("Onboarding")
        case .sessionSetup:
            Text("Session Setup")
        case .interviewRoom:
            InterviewView(viewModel: InterviewViewModel(
                router: router,
                speechService: SpeechService(),
                analysisService: AnalysisService()
            ))
        case .analytics:
            Text("Analytics")
        case .history:
            Text("History")
        case .settings:
            Text("Settings")
        case .audioTest:
            AudioTestView()
        }
    }
}

#Preview {
    ContentView()
        .environment(Router())
        .environment(AppState())
}
