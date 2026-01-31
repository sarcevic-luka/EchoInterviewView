import Foundation

final class SimpleScoringService {
    func calculateScores(metrics: NLPMetrics) -> AnswerScores {
        let overall = calculateOverallScore(metrics: metrics)
        let clarity = calculateClarity(metrics: metrics)
        let confidence = overall > 70 ? 80.0 : 60.0
        let technical = 70.0
        let pace = calculatePaceScore(speechRate: metrics.speechRate)
        
        return AnswerScores(
            overall: overall,
            clarity: clarity,
            confidence: confidence,
            technical: technical,
            pace: pace
        )
    }
    
    private func calculateOverallScore(metrics: NLPMetrics) -> Double {
        let baseline = 50.0
        
        let wordCountBonus: Double
        if metrics.totalWordCount >= 20 && metrics.totalWordCount <= 100 {
            wordCountBonus = 30
        } else if metrics.totalWordCount >= 10 && metrics.totalWordCount < 20 {
            wordCountBonus = 15
        } else {
            wordCountBonus = 5
        }
        
        let fillerPenalty = Double(metrics.fillerWordCount) * 2
        
        let score = baseline + wordCountBonus - fillerPenalty
        return min(max(score, 0), 100)
    }
    
    private func calculateClarity(metrics: NLPMetrics) -> Double {
        let totalWords = max(metrics.totalWordCount, 1)
        let fillerRatio = Double(metrics.fillerWordCount) / Double(totalWords)
        let clarity = 100 - (fillerRatio * 100)
        return min(max(clarity, 0), 100)
    }
    
    private func calculatePaceScore(speechRate: Double) -> Double {
        if speechRate >= 120 && speechRate <= 180 {
            return 80
        } else {
            return 60
        }
    }
}
