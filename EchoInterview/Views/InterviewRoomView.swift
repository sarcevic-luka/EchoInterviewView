import SwiftUI

struct InterviewRoomView: View {
    @Bindable var viewModel: InterviewSessionViewModel
    @Environment(Router.self) private var router
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 32) {
            progressSection
            questionSection
            stateSection
            actionButton
            Spacer()
        }
        .padding()
        .navigationTitle("Interview")
        .navigationBarTitleDisplayMode(.inline)
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
            Text("Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .tint(.blue)
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
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - State Section
    
    private var stateSection: some View {
        VStack(spacing: 16) {
            stateLabel
            transcriptView
        }
        .frame(minHeight: 150)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var stateLabel: some View {
        switch viewModel.currentState {
        case .idle:
            Label("Ready to Begin", systemImage: "play.circle")
                .font(.headline)
                .foregroundStyle(.secondary)
            
        case .listening:
            Label("Listening for Question...", systemImage: "speaker.wave.2")
                .font(.headline)
                .foregroundStyle(.blue)
            
        case .speaking:
            Label("Recording Your Answer", systemImage: "mic.fill")
                .font(.headline)
                .foregroundStyle(.red)
            
        case .analyzing:
            Label("Analyzing...", systemImage: "brain")
                .font(.headline)
                .foregroundStyle(.orange)
            
        case .showingResults:
            Label("Answer Recorded", systemImage: "checkmark.circle")
                .font(.headline)
                .foregroundStyle(.green)
            
        case .error:
            Label("Error Occurred", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.red)
        }
    }
    
    @ViewBuilder
    private var transcriptView: some View {
        switch viewModel.currentState {
        case .speaking(let transcript):
            if transcript.isEmpty {
                Text("Start speaking...")
                    .foregroundStyle(.secondary)
                    .italic()
            } else {
                ScrollView {
                    Text(transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 100)
            }
            
        case .showingResults:
            if let lastAnswer = viewModel.answers.last {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Score: \(Int(lastAnswer.scores.overall))/100")
                        .font(.headline)
                        .foregroundStyle(scoreColor(for: lastAnswer.scores.overall))
                    
                    Text(lastAnswer.transcript)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
        case .analyzing:
            ProgressView()
                .progressViewStyle(.circular)
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.currentState {
        case .idle:
            Button {
                viewModel.beginInterview()
            } label: {
                Label("Begin Interview", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            
        case .listening:
            Button {
                viewModel.startListening()
            } label: {
                Label("Tap to Answer", systemImage: "mic.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
        case .speaking:
            Button {
                viewModel.analyzeAnswer()
            } label: {
                Label("Done Speaking", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
        case .analyzing:
            Button {} label: {
                Label("Analyzing...", systemImage: "hourglass")
                    .font(.headline)
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
                Button {
                    viewModel.nextQuestion()
                } label: {
                    Label("Next Question", systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            
        case .error:
            Button {
                viewModel.resetInterview()
            } label: {
                Label("Try Again", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
    
    // MARK: - Helpers
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

#Preview("Idle State") {
    NavigationStack {
        InterviewRoomView(viewModel: InterviewSessionViewModel())
            .environment(Router())
    }
}
