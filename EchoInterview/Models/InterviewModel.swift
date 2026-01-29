import Foundation

struct InterviewModel: Identifiable, Codable {
    let id: UUID
    let type: InterviewType
    let difficulty: Difficulty
    let duration: TimeInterval
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        type: InterviewType,
        difficulty: Difficulty,
        duration: TimeInterval,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.difficulty = difficulty
        self.duration = duration
        self.createdAt = createdAt
    }
}

enum InterviewType: String, Codable {
    case technical
    case behavioral
    case systemDesign
}

enum Difficulty: String, Codable {
    case beginner
    case intermediate
    case advanced
}

