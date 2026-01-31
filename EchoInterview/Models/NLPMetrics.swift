import Foundation

struct NLPMetrics: Codable, Equatable {
    let totalWordCount: Int
    let fillerWordCount: Int
    let speechRate: Double
    
    init(totalWordCount: Int, fillerWordCount: Int, speechRate: Double) {
        self.totalWordCount = totalWordCount
        self.fillerWordCount = fillerWordCount
        self.speechRate = speechRate
    }
}
