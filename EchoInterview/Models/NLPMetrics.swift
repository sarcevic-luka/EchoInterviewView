import Foundation

struct NLPMetrics: Codable, Equatable {
    let totalWordCount: Int
    let fillerWordCount: Int
    let speechRate: Double
    let semanticSimilarity: Double
    
    init(
        totalWordCount: Int,
        fillerWordCount: Int,
        speechRate: Double,
        semanticSimilarity: Double = 0
    ) {
        self.totalWordCount = totalWordCount
        self.fillerWordCount = fillerWordCount
        self.speechRate = speechRate
        self.semanticSimilarity = semanticSimilarity
    }
}
