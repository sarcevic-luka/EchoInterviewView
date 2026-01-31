import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dashboard")
                .font(.largeTitle)
            
            Button("Test Microphone Permission") {
                viewModel.navigateToAudioTest()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(router: Router()))
}

