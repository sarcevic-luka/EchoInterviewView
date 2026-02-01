import SwiftUI

struct OnboardingView: View {
    @Environment(\.serviceContainer) private var serviceContainer
    
    @State private var currentStep = 0
    @State private var micPermissionGranted = false
    @State private var speechPermissionGranted = false
    @State private var isTestingVoice = false
    @State private var voiceTestPassed = false
    @State private var testTranscript = ""
    
    let onComplete: () -> Void
    
    private let totalSteps = 5
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .progressViewStyle(.linear)
                .tint(.blue)
                .padding()
            
            Spacer()
            
            // Content
            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                micPermissionStep.tag(1)
                speechPermissionStep.tag(2)
                voiceTestStep.tag(3)
                completionStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
            
            Spacer()
            
            // Navigation Button
            navigationButton
                .padding()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Step 0: Welcome
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 100))
                .foregroundStyle(.blue.gradient)
            
            Text("Welcome to\nNeural Interview Trainer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Practice your interview skills with AI-powered analysis and real-time feedback.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Step 1: Microphone Permission
    
    private var micPermissionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(micPermissionGranted ? .green : .blue)
            
            Text("Microphone Access")
                .font(.title)
                .fontWeight(.bold)
            
            Text("We need access to your microphone to record your interview answers.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if micPermissionGranted {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            }
        }
        .padding()
    }
    
    // MARK: - Step 2: Speech Permission
    
    private var speechPermissionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(speechPermissionGranted ? .green : .blue)
            
            Text("Speech Recognition")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Speech recognition converts your spoken answers to text for analysis.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if speechPermissionGranted {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            }
        }
        .padding()
    }
    
    // MARK: - Step 3: Voice Test
    
    private var voiceTestStep: some View {
        VStack(spacing: 24) {
            Image(systemName: voiceTestPassed ? "checkmark.circle.fill" : "mic.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(voiceTestPassed ? .green : .orange)
            
            Text("Voice Test")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Let's make sure everything works. Tap the button and say a few words.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isTestingVoice {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Listening...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !testTranscript.isEmpty {
                        Text(testTranscript)
                            .font(.body)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else if voiceTestPassed {
                VStack(spacing: 8) {
                    Label("Voice Test Passed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)
                    
                    Text("We heard: \"\(testTranscript)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    startVoiceTest()
                } label: {
                    Label("Start Voice Test", systemImage: "mic.fill")
                        .font(.headline)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding()
    }
    
    // MARK: - Step 4: Completion
    
    private var completionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green.gradient)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You're ready to start practicing interviews. Good luck!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Navigation Button
    
    private var navigationButton: some View {
        Button {
            handleNavigation()
        } label: {
            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isButtonDisabled)
    }
    
    private var buttonTitle: String {
        switch currentStep {
        case 0: return "Get Started"
        case 1: return micPermissionGranted ? "Continue" : "Grant Access"
        case 2: return speechPermissionGranted ? "Continue" : "Grant Access"
        case 3: return voiceTestPassed ? "Continue" : "Skip Test"
        case 4: return "Start Training"
        default: return "Continue"
        }
    }
    
    private var isButtonDisabled: Bool {
        isTestingVoice
    }
    
    // MARK: - Actions
    
    private func handleNavigation() {
        switch currentStep {
        case 0:
            withAnimation { currentStep = 1 }
            
        case 1:
            if micPermissionGranted {
                withAnimation { currentStep = 2 }
            } else {
                requestMicPermission()
            }
            
        case 2:
            if speechPermissionGranted {
                withAnimation { currentStep = 3 }
            } else {
                requestSpeechPermission()
            }
            
        case 3:
            withAnimation { currentStep = 4 }
            
        case 4:
            completeOnboarding()
            
        default:
            break
        }
    }
    
    private func requestMicPermission() {
        Task {
            let granted = await serviceContainer.audioService.requestMicrophonePermission()
            micPermissionGranted = granted
            if granted {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation { currentStep = 2 }
            }
        }
    }
    
    private func requestSpeechPermission() {
        Task {
            let granted = await serviceContainer.speechService.requestAuthorization()
            speechPermissionGranted = granted
            if granted {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation { currentStep = 3 }
            }
        }
    }
    
    private func startVoiceTest() {
        isTestingVoice = true
        testTranscript = ""
        
        Task {
            do {
                let audioStream = try await serviceContainer.audioService.startRecording()
                let transcriptStream = try await serviceContainer.speechService.startRecognition(audioStream: audioStream)
                
                // Listen for 3 seconds
                let deadline = Date().addingTimeInterval(3)
                
                for await transcript in transcriptStream {
                    testTranscript = transcript
                    if Date() >= deadline {
                        break
                    }
                }
                
                await serviceContainer.audioService.stopRecording()
                _ = await serviceContainer.speechService.stopRecognition()
                
                isTestingVoice = false
                voiceTestPassed = !testTranscript.isEmpty
            } catch {
                isTestingVoice = false
                voiceTestPassed = false
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "firstLaunchComplete")
        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environment(\.serviceContainer, .shared)
}
