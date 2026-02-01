import SwiftUI

struct AnalyticsView: View {
    @Bindable var viewModel: AnalyticsViewModel
    @State private var isTranscriptExpanded = false
    
    let onDone: () -> Void
    var onSaveSession: (() async -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                overallScoreSection
                scoreBreakdownSection
                metricsSection
                coachingTipsSection
                transcriptSection
                doneButton
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await onSaveSession?()
        }
    }
    
    // MARK: - Overall Score Section
    
    private var overallScoreSection: some View {
        VStack(spacing: 8) {
            Text("Overall Score")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("\(Int(viewModel.overallScore))")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(scoreColor(for: viewModel.overallScore))
            
            Text("out of 100")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Score Breakdown Section
    
    private var scoreBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Score Breakdown", systemImage: "chart.bar.fill")
                .font(.headline)
            
            ScoreProgressRow(
                icon: "text.alignleft",
                label: "Clarity",
                score: viewModel.averageClarity
            )
            
            ScoreProgressRow(
                icon: "person.fill.checkmark",
                label: "Confidence",
                score: viewModel.averageConfidence
            )
            
            ScoreProgressRow(
                icon: "wrench.and.screwdriver.fill",
                label: "Technical",
                score: viewModel.averageTechnical
            )
            
            ScoreProgressRow(
                icon: "speedometer",
                label: "Pace",
                score: viewModel.averagePace
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Metrics Section
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Speech Metrics", systemImage: "waveform")
                .font(.headline)
            
            HStack(spacing: 12) {
                MetricCard(
                    icon: "textformat.123",
                    title: "Words",
                    value: "\(viewModel.totalWordCount)"
                )
                
                MetricCard(
                    icon: "exclamationmark.bubble",
                    title: "Fillers",
                    value: "\(viewModel.totalFillerWords)"
                )
                
                MetricCard(
                    icon: "gauge.with.needle",
                    title: "WPM",
                    value: String(format: "%.0f", viewModel.averageSpeechRate)
                )
                
                MetricCard(
                    icon: "brain.head.profile",
                    title: "Relevance",
                    value: String(format: "%.0f%%", viewModel.averageSemanticSimilarity * 100)
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Coaching Tips Section
    
    private var coachingTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Coaching Tips", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            
            ForEach(viewModel.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                    
                    Text(tip)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Transcript Section
    
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTranscriptExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("Full Transcript", systemImage: "doc.text")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: isTranscriptExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isTranscriptExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(viewModel.answers.enumerated()), id: \.offset) { index, answer in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Q\(index + 1): \(viewModel.questions[index].text)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                            
                            Text(answer.transcript)
                                .font(.subheadline)
                            
                            HStack(spacing: 16) {
                                Label("\(Int(answer.scores.overall))", systemImage: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(scoreColor(for: answer.scores.overall))
                                
                                Label("\(answer.metrics.totalWordCount) words", systemImage: "textformat.123")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Label(String(format: "%.0f wpm", answer.metrics.speechRate), systemImage: "speedometer")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Done Button
    
    private var doneButton: some View {
        Button {
            onDone()
        } label: {
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
    }
    
    // MARK: - Helpers
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

// MARK: - Score Progress Row

private struct ScoreProgressRow: View {
    let icon: String
    let label: String
    let score: Double
    
    private var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            
            Text(label)
                .frame(width: 80, alignment: .leading)
            
            ProgressView(value: score, total: 100)
                .progressViewStyle(.linear)
                .tint(scoreColor)
            
            Text("\(Int(score))")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(scoreColor)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Metric Card

private struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let mockAnswers = [
        Answer(
            transcript: "I recently worked on a mobile app that helped users track their fitness goals. The project involved SwiftUI, Core Data, and HealthKit integration.",
            duration: 15,
            metrics: NLPMetrics(totalWordCount: 50, fillerWordCount: 2, speechRate: 150),
            scores: AnswerScores(overall: 78, clarity: 85, confidence: 70, technical: 70, pace: 80)
        ),
        Answer(
            transcript: "The biggest challenge was optimizing database queries for performance. I used profiling tools to identify bottlenecks and implemented caching.",
            duration: 12,
            metrics: NLPMetrics(totalWordCount: 40, fillerWordCount: 1, speechRate: 140),
            scores: AnswerScores(overall: 82, clarity: 90, confidence: 80, technical: 70, pace: 80)
        ),
        Answer(
            transcript: "I prioritize tasks using a combination of urgency and impact. I use tools like Jira to track progress and communicate regularly with stakeholders.",
            duration: 10,
            metrics: NLPMetrics(totalWordCount: 35, fillerWordCount: 0, speechRate: 160),
            scores: AnswerScores(overall: 85, clarity: 92, confidence: 85, technical: 70, pace: 80)
        )
    ]
    
    let questions = [
        Question(text: "Tell me about a recent project you're proud of."),
        Question(text: "Describe a technical challenge you faced."),
        Question(text: "How do you prioritize tasks?")
    ]
    
    NavigationStack {
        AnalyticsView(
            viewModel: AnalyticsViewModel(answers: mockAnswers, questions: questions),
            onDone: {},
            onSaveSession: nil
        )
    }
}
