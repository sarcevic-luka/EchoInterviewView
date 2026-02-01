import Foundation

struct NLPMetrics: Codable, Equatable {
    let totalWordCount: Int
    let fillerWordCount: Int
    let speechRate: Double
    let semanticSimilarity: Double
    let sentenceCount: Int
    let pauseCount: Int
    let keywordCoverage: Double
    
    var fillerRatio: Double {
        Double(fillerWordCount) / Double(max(totalWordCount, 1))
    }
    
    var avgSentenceLength: Double {
        Double(totalWordCount) / Double(max(sentenceCount, 1))
    }
    
    init(
        totalWordCount: Int,
        fillerWordCount: Int,
        speechRate: Double,
        semanticSimilarity: Double = 0,
        sentenceCount: Int = 1,
        pauseCount: Int = 0,
        keywordCoverage: Double = 0
    ) {
        self.totalWordCount = totalWordCount
        self.fillerWordCount = fillerWordCount
        self.speechRate = speechRate
        self.semanticSimilarity = semanticSimilarity
        self.sentenceCount = sentenceCount
        self.pauseCount = pauseCount
        self.keywordCoverage = keywordCoverage
    }
}
