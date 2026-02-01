import SwiftUI
import SwiftData

struct HistoryView: View {
    @Bindable var viewModel: HistoryViewModel
    @Environment(Router.self) private var router
    @State private var selectedSession: SessionDetailData?
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading history...")
            } else if viewModel.sessions.isEmpty {
                emptyStateView
            } else {
                sessionListView
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadSessions()
        }
        .sheet(item: $selectedSession) { sessionData in
            NavigationStack {
                AnalyticsView(
                    viewModel: AnalyticsViewModel(
                        answers: sessionData.answers,
                        questions: sessionData.answers.enumerated().map { index, _ in
                            Question(text: "Question \(index + 1)")
                        }
                    ),
                    onDone: {
                        selectedSession = nil
                    },
                    onSaveSession: nil
                )
            }
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Interview History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete an interview to see your results here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Session List
    
    private var sessionListView: some View {
        List {
            ForEach(viewModel.sessions, id: \.id) { session in
                SessionCard(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let answers = session.toAnswers()
                        selectedSession = SessionDetailData(
                            id: session.id,
                            answers: answers,
                            interviewType: session.interviewType,
                            date: session.date
                        )
                    }
            }
            .onDelete { offsets in
                viewModel.deleteSession(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Session Detail Data

struct SessionDetailData: Identifiable {
    let id: UUID
    let answers: [Answer]
    let interviewType: String
    let date: Date
}

// MARK: - Session Card

private struct SessionCard: View {
    let session: InterviewSessionEntity
    
    private var scoreColor: Color {
        if session.overallScore >= 80 { return .green }
        if session.overallScore >= 60 { return .orange }
        return .red
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: session.overallScore / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(session.overallScore))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor)
            }
            .frame(width: 50, height: 50)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(session.interviewType)
                    .font(.headline)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                let answerCount = session.toAnswers().count
                Text("\(answerCount) question\(answerCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

