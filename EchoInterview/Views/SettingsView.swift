import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showClearConfirmation = false
    
    var body: some View {
        List {
            voiceSection
            permissionsSection
            dataSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadPermissionStatus()
            await viewModel.loadSessionCount()
        }
        .alert("Clear All History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearAllHistory()
                }
            }
        } message: {
            Text("This will permanently delete all \(viewModel.sessionCount) interview sessions. This action cannot be undone.")
        }
    }
    
    // MARK: - Voice Section
    
    private var voiceSection: some View {
        Section {
            Picker("Voice", selection: $viewModel.selectedVoiceIdentifier) {
                ForEach(viewModel.availableVoices, id: \.identifier) { voice in
                    Text(voice.name)
                        .tag(voice.identifier)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speech Rate")
                    Spacer()
                    Text(speechRateLabel)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $viewModel.speechRate, in: 0.4...0.6, step: 0.05)
            }
        } header: {
            Label("Voice Settings", systemImage: "speaker.wave.2")
        } footer: {
            Text("Adjust how questions are read aloud during interviews.")
        }
    }
    
    private var speechRateLabel: String {
        if viewModel.speechRate < 0.45 {
            return "Slow"
        } else if viewModel.speechRate > 0.55 {
            return "Fast"
        } else {
            return "Normal"
        }
    }
    
    // MARK: - Permissions Section
    
    private var permissionsSection: some View {
        Section {
            PermissionRow(
                title: "Microphone",
                icon: "mic.fill",
                status: viewModel.micPermissionStatus
            )
            
            PermissionRow(
                title: "Speech Recognition",
                icon: "waveform",
                status: viewModel.speechPermissionStatus
            )
            
            if viewModel.micPermissionStatus == .denied || viewModel.speechPermissionStatus == .denied {
                Button {
                    openSettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
            }
        } header: {
            Label("Permissions", systemImage: "lock.shield")
        } footer: {
            Text("Both permissions are required for the interview features to work properly.")
        }
    }
    
    // MARK: - Data Section
    
    private var dataSection: some View {
        Section {
            HStack {
                Label("Interview Sessions", systemImage: "clock.arrow.circlepath")
                Spacer()
                Text("\(viewModel.sessionCount)")
                    .foregroundStyle(.secondary)
            }
            
            Button(role: .destructive) {
                showClearConfirmation = true
            } label: {
                Label("Clear All History", systemImage: "trash")
            }
            .disabled(viewModel.sessionCount == 0 || viewModel.isClearingHistory)
        } header: {
            Label("Data", systemImage: "internaldrive")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("About", systemImage: "info.circle")
        }
    }
    
    // MARK: - Helpers
    
    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Permission Row

private struct PermissionRow: View {
    let title: String
    let icon: String
    let status: SettingsViewModel.PermissionStatus
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: status.iconName)
                    .foregroundStyle(status.color)
                Text(status.displayText)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
}
