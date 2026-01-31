import Foundation

struct Answer: Codable, Equatable, Identifiable {
    let id: UUID
    let transcript: String
    let duration: TimeInterval
    let metrics: NLPMetrics
    let scores: AnswerScores
    
    init(
        id: UUID = UUID(),
        transcript: String,
        duration: TimeInterval,
        metrics: NLPMetrics,
        scores: AnswerScores
    ) {
        self.id = id
        self.transcript = transcript
        self.duration = duration
        self.metrics = metrics
        self.scores = scores
    }
}
