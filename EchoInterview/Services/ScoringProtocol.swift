import Foundation

protocol ScoringProtocol {
    func calculateScores(metrics: NLPMetrics) throws -> AnswerScores
    func calculateScores(metrics: NLPMetrics, transcript: String) throws -> AnswerScores
}

extension ScoringProtocol {
    // Default implementation calls the basic method
    func calculateScores(metrics: NLPMetrics, transcript: String) throws -> AnswerScores {
        try calculateScores(metrics: metrics)
    }
}
