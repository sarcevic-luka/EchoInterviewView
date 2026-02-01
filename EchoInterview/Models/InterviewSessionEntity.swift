import SwiftData
import Foundation

@Model
final class InterviewSessionEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var interviewType: String
    var overallScore: Double
    var answersData: Data
    
    init(id: UUID, date: Date, interviewType: String, overallScore: Double, answersData: Data) {
        self.id = id
        self.date = date
        self.interviewType = interviewType
        self.overallScore = overallScore
        self.answersData = answersData
    }
    
    func toAnswers() -> [Answer] {
        guard let answers = try? JSONDecoder().decode([Answer].self, from: answersData) else {
            return []
        }
        return answers
    }
    
    static func from(answers: [Answer], interviewType: String) -> InterviewSessionEntity? {
        guard !answers.isEmpty,
              let data = try? JSONEncoder().encode(answers) else {
            return nil
        }
        
        let avgScore = answers.map(\.scores.overall).reduce(0, +) / Double(answers.count)
        
        return InterviewSessionEntity(
            id: UUID(),
            date: Date(),
            interviewType: interviewType,
            overallScore: avgScore,
            answersData: data
        )
    }
}
