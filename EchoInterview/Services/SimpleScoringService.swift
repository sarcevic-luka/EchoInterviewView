import Foundation

final class SimpleScoringService: ScoringProtocol {
    func calculateScores(metrics: NLPMetrics) throws -> AnswerScores {
        let clarity = calculateClarity(metrics: metrics)
        let technical = calculateTechnicalScore(metrics: metrics)
        let pace = calculatePaceScore(speechRate: metrics.speechRate)
        let overall = calculateOverallScore(metrics: metrics, technical: technical)
        let confidence = calculateConfidence(overall: overall, semanticSimilarity: metrics.semanticSimilarity)
        
        return AnswerScores(
            overall: overall,
            clarity: clarity,
            confidence: confidence,
            technical: technical,
            pace: pace
        )
    }
    
    private func calculateOverallScore(metrics: NLPMetrics, technical: Double) -> Double {
        let baseline = 40.0
        
        // Word count bonus (max 20 points)
        let wordCountBonus: Double
        if metrics.totalWordCount >= 20 && metrics.totalWordCount <= 100 {
            wordCountBonus = 20
        } else if metrics.totalWordCount >= 10 && metrics.totalWordCount < 20 {
            wordCountBonus = 10
        } else {
            wordCountBonus = 5
        }
        
        // Filler penalty
        let fillerPenalty = Double(metrics.fillerWordCount) * 2
        
        // Semantic similarity bonus (max 30 points)
        let semanticBonus = metrics.semanticSimilarity * 30
        
        // Technical contribution (max 10 points from technical score)
        let technicalBonus = (technical / 100) * 10
        
        let score = baseline + wordCountBonus + semanticBonus + technicalBonus - fillerPenalty
        return min(max(score, 0), 100)
    }
    
    private func calculateClarity(metrics: NLPMetrics) -> Double {
        let totalWords = max(metrics.totalWordCount, 1)
        let fillerRatio = Double(metrics.fillerWordCount) / Double(totalWords)
        let clarity = 100 - (fillerRatio * 100)
        return min(max(clarity, 0), 100)
    }
    
    private func calculateTechnicalScore(metrics: NLPMetrics) -> Double {
        // Technical score based on semantic similarity to ideal answer
        // Higher similarity = more relevant/technical content
        let baseScore = 50.0
        let similarityBonus = metrics.semanticSimilarity * 50
        return min(max(baseScore + similarityBonus, 0), 100)
    }
    
    private func calculateConfidence(overall: Double, semanticSimilarity: Double) -> Double {
        // Confidence based on overall performance and semantic coherence
        let baseConfidence = overall > 70 ? 75.0 : 55.0
        let coherenceBonus = semanticSimilarity * 20
        return min(max(baseConfidence + coherenceBonus, 0), 100)
    }
    
    private func calculatePaceScore(speechRate: Double) -> Double {
        // Ideal range: 120-180 wpm
        if speechRate >= 120 && speechRate <= 180 {
            return 90
        } else if speechRate >= 100 && speechRate <= 200 {
            return 70
        } else {
            return 50
        }
    }
}
