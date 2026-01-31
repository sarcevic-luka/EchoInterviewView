import SwiftUI

struct InterviewRoomView: View {
    @Bindable var viewModel: InterviewSessionViewModel
    
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
                    InterviewResultsView(answers: viewModel.answers, questions: viewModel.questions)
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
        }
    }
    
    // MARK: - Helpers
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

// MARK: - Results View (Placeholder)

struct InterviewResultsView: View {
    let answers: [Answer]
    let questions: [Question]
    
    var averageScore: Double {
        guard !answers.isEmpty else { return 0 }
        return answers.reduce(0) { $0 + $1.scores.overall } / Double(answers.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall Score
                VStack(spacing: 8) {
                    Text("Overall Score")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(averageScore))")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(scoreColor(for: averageScore))
                    
                    Text("out of 100")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Individual Answers
                ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Q\(index + 1): \(questions[index].text)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(answer.transcript)
                            .font(.body)
                        
                        HStack {
                            ScoreLabel(title: "Overall", score: answer.scores.overall)
                            ScoreLabel(title: "Clarity", score: answer.scores.clarity)
                            ScoreLabel(title: "Pace", score: answer.scores.pace)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("Results")
    }
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

private struct ScoreLabel: View {
    let title: String
    let score: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(Int(score))")
                .font(.caption)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Idle State") {
    NavigationStack {
        InterviewRoomView(viewModel: InterviewSessionViewModel())
    }
}

#Preview("Results") {
    let mockAnswers = [
        Answer(
            transcript: "I recently worked on a mobile app that helped users track their fitness goals.",
            duration: 15,
            metrics: NLPMetrics(totalWordCount: 50, fillerWordCount: 2, speechRate: 150),
            scores: AnswerScores(overall: 78, clarity: 85, confidence: 70, technical: 70, pace: 80)
        ),
        Answer(
            transcript: "The biggest challenge was optimizing database queries for performance.",
            duration: 12,
            metrics: NLPMetrics(totalWordCount: 40, fillerWordCount: 1, speechRate: 140),
            scores: AnswerScores(overall: 82, clarity: 90, confidence: 80, technical: 70, pace: 80)
        )
    ]
    
    let questions = [
        Question(text: "Tell me about a recent project you're proud of."),
        Question(text: "Describe a technical challenge you faced.")
    ]
    
    NavigationStack {
        InterviewResultsView(answers: mockAnswers, questions: questions)
    }
}
