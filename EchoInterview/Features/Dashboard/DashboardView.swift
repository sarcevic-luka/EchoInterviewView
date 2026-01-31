import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            headerSection
            
            Spacer()
            
            startInterviewButton
            
            audioTestButton
            
            Spacer()
        }
        .padding()
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionAlertMessage)
        }
        .task {
            await viewModel.checkPermissions()
        }
        .onChange(of: viewModel.permissionError) { _, error in
            if let error {
                permissionAlertMessage = error
                showPermissionAlert = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            Text("Neural Interview Trainer")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Practice your interview skills with AI-powered feedback")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Start Interview Button
    
    private var startInterviewButton: some View {
        Button {
            Task {
                await viewModel.startInterview()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("Start Interview")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(viewModel.isCheckingPermissions)
    }
    
    // MARK: - Audio Test Button
    
    private var audioTestButton: some View {
        Button {
            viewModel.navigateToAudioTest()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.badge.plus")
                Text("Test Audio & Permissions")
            }
            .font(.subheadline)
        }
        .buttonStyle(.bordered)
    }
    
    // MARK: - Helpers
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        DashboardView(viewModel: DashboardViewModel(
            router: Router(),
            serviceContainer: .shared
        ))
    }
}
