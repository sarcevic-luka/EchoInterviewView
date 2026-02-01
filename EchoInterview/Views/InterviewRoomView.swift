import SwiftUI

struct InterviewRoomView: View {
    @Bindable var viewModel: InterviewSessionViewModel
    @Environment(Router.self) private var router
    @State private var showErrorAlert = false
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            progressSection
            questionSection
            stateSection
            actionButton
            Spacer()
        }
        .padding()
        .navigationTitle("Interview")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentState)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .onChange(of: viewModel.errorMessage) { _, error in
            showErrorAlert = error != nil
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.totalQuestions)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(.blue)
                .animation(.easeInOut, value: viewModel.progress)
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        VStack(spacing: 16) {
            if let question = viewModel.currentQuestion {
                Text(question.text)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.4), value: viewModel.currentQuestion?.id)
    }
    
    // MARK: - State Section
    
    private var stateSection: some View {
        VStack(spacing: 16) {
            stateIndicator
            transcriptView
        }
        .frame(minHeight: 200)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var stateIndicator: some View {
        switch viewModel.currentState {
        case .idle:
            VStack(spacing: 16) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                Text("Ready to Begin")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .transition(.opacity)
            
        case .listening:
            VStack(spacing: 16) {
                WaveformView(amplitude: 0.2, sentiment: .neutral, isAnimating: true)
                HStack(spacing: 8) {
                    PulsingDotView(color: .blue)
                    Text("Tap below to answer")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
            .transition(.opacity)
            
        case .speaking(let transcript):
            VStack(spacing: 16) {
                WaveformView(
                    amplitude: calculateAmplitude(from: transcript),
                    sentiment: .confident,
                    isAnimating: true
                )
                HStack(spacing: 8) {
                    PulsingDotView(color: .red)
                    Text("Recording...")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
            }
            .transition(.opacity)
            
        case .analyzing:
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                Text("Analyzing your answer...")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            .transition(.opacity)
            
        case .showingResults:
            if let lastAnswer = viewModel.answers.last {
                VStack(spacing: 8) {
                    Text("\(Int(lastAnswer.scores.overall))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(scoreColor(for: lastAnswer.scores.overall))
                    Text("Score")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
        case .error:
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.red)
                Text("Something went wrong")
                    .font(.headline)
                    .foregroundStyle(.red)
            }
            .transition(.opacity)
        }
    }
    
    @ViewBuilder
    private var transcriptView: some View {
        switch viewModel.currentState {
        case .speaking(let transcript):
            if !transcript.isEmpty {
                ScrollView {
                    Text(transcript)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeOut, value: transcript)
                }
                .frame(maxHeight: 80)
                .transition(.opacity)
            }
            
        case .showingResults:
            if let lastAnswer = viewModel.answers.last {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lastAnswer.transcript)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private var actionButton: some View {
        Group {
            switch viewModel.currentState {
            case .idle:
                AnimatedButton(
                    title: "Begin Interview",
                    icon: "play.fill",
                    color: .blue
                ) {
                    viewModel.beginInterview()
                }
                
            case .listening:
                AnimatedButton(
                    title: "Tap to Answer",
                    icon: "mic.fill",
                    color: .blue
                ) {
                    viewModel.startListening()
                }
                
            case .speaking:
                AnimatedButton(
                    title: "Done Speaking",
                    icon: "stop.fill",
                    color: .red
                ) {
                    viewModel.analyzeAnswer()
                }
                
            case .analyzing:
                Button {} label: {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Analyzing...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(true)
                
            case .showingResults:
                if viewModel.isLastQuestion {
                    NavigationLink {
                        AnalyticsView(
                            viewModel: AnalyticsViewModel(
                                answers: viewModel.answers,
                                questions: viewModel.questions
                            ),
                            onDone: {
                                router.navigateToRoot()
                            },
                            onSaveSession: {
                                await viewModel.completeInterview()
                            }
                        )
                    } label: {
                        Label("View Results", systemImage: "chart.bar.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    AnimatedButton(
                        title: "Next Question",
                        icon: "arrow.right",
                        color: .green
                    ) {
                        viewModel.nextQuestion()
                    }
                }
                
            case .error:
                AnimatedButton(
                    title: "Try Again",
                    icon: "arrow.counterclockwise",
                    color: .red
                ) {
                    viewModel.resetInterview()
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Helpers
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private func calculateAmplitude(from transcript: String) -> Double {
        // Simple amplitude based on recent text length changes
        let wordCount = transcript.split(separator: " ").count
        return min(1.0, Double(wordCount % 10) / 10.0 + 0.3)
    }
}

// MARK: - Animated Button

private struct AnimatedButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        } label: {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview("Idle State") {
    NavigationStack {
        InterviewRoomView(viewModel: InterviewSessionViewModel())
            .environment(Router())
    }
}
