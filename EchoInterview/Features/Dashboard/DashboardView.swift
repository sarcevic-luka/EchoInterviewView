import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    startInterviewButton
                    
                    if !viewModel.recentSessions.isEmpty {
                        recentSessionsSection
                    }
                }
                .padding()
            }
            
            tabBar
        }
        .navigationTitle("Interview Trainer")
        .navigationBarTitleDisplayMode(.large)
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
            await viewModel.loadRecentSessions()
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
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)
            
            Text("Practice makes perfect")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
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
    
    // MARK: - Recent Sessions Section
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Sessions", systemImage: "clock")
                    .font(.headline)
                
                Spacer()
                
                Button("See All") {
                    viewModel.navigateToHistory()
                }
                .font(.subheadline)
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.recentSessions, id: \.id) { session in
                    RecentSessionRow(session: session)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            TabBarButton(
                title: "Home",
                icon: "house.fill",
                isSelected: true
            ) {
                // Already on home
            }
            
            TabBarButton(
                title: "History",
                icon: "clock.arrow.circlepath",
                isSelected: false
            ) {
                viewModel.navigateToHistory()
            }
            
            TabBarButton(
                title: "Audio Test",
                icon: "mic.badge.plus",
                isSelected: false
            ) {
                viewModel.navigateToAudioTest()
            }
            
            TabBarButton(
                title: "Settings",
                icon: "gear",
                isSelected: false
            ) {
                viewModel.navigateToSettings()
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Color(.secondarySystemBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Helpers
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Tab Bar Button

private struct TabBarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Session Row

private struct RecentSessionRow: View {
    let session: InterviewSessionEntity
    
    private var scoreColor: Color {
        if session.overallScore >= 80 { return .green }
        if session.overallScore >= 60 { return .orange }
        return .red
    }
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.date, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.interviewType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(session.overallScore))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(scoreColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
