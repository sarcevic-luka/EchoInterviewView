import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dashboard")
                .font(.largeTitle)
            
            Button("Start Interview Session") {
                viewModel.navigateToInterviewSession()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            Button("Test Audio & Permissions") {
                viewModel.navigateToAudioTest()
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(router: Router()))
}

