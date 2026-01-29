import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    
    var body: some View {
        Text("Dashboard")
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(router: Router()))
}

