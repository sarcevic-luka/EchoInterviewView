import Foundation

struct AnswerScores: Codable, Equatable {
    let overall: Double
    let clarity: Double
    let confidence: Double
    let technical: Double
    let pace: Double
    
    init(overall: Double, clarity: Double, confidence: Double, technical: Double, pace: Double) {
        self.overall = overall
        self.clarity = clarity
        self.confidence = confidence
        self.technical = technical
        self.pace = pace
    }
}
