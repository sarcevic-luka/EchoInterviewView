import SwiftUI

struct AudioTestView: View {
    @State private var permissionStatus: String = "Not requested"
    @State private var isRequesting = false
    
    private let audioService: any AudioService
    
    init(audioService: any AudioService = AudioServiceImpl()) {
        self.audioService = audioService
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Microphone Permission Test")
                .font(.headline)
            
            Text(permissionStatus)
                .font(.body)
                .foregroundStyle(statusColor)
            
            Button {
                requestPermission()
            } label: {
                if isRequesting {
                    ProgressView()
                } else {
                    Text("Request Microphone Permission")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)
        }
        .padding()
    }
    
    private var statusColor: Color {
        switch permissionStatus {
        case "Granted":
            return .green
        case "Denied":
            return .red
        default:
            return .secondary
        }
    }
    
    private func requestPermission() {
        isRequesting = true
        Task {
            let granted = await audioService.requestMicrophonePermission()
            await MainActor.run {
                permissionStatus = granted ? "Granted" : "Denied"
                isRequesting = false
            }
        }
    }
}

#Preview {
    AudioTestView()
}
