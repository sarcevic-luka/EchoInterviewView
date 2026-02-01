import Foundation

@MainActor
@Observable
final class AnalyticsViewModel {
    let answers: [Answer]
    let questions: [Question]
    
    let tips: [String] = [
        "Practice reducing filler words like 'um' and 'uh'",
        "Aim for 30-50 word answers with clear structure",
        "Use the STAR method: Situation, Task, Action, Result"
    ]
    
    var overallScore: Double {
        guard !answers.isEmpty else { return 0 }
        return answers.reduce(0) { $0 + $1.scores.overall } / Double(answers.count)
    }
    
    var averageClarity: Double {
        guard !answers.isEmpty else { return 0 }
        return answers.reduce(0) { $0 + $1.scores.clarity } / Double(answers.count)
    }
    
    var averageConfidence: Double {
        guard !answers.isEmpty else { return 0 }
        return answers.reduce(0) { $0 + $1.scores.confidence } / Double(answers.count)
    }
    
    var averageTechnical: Double {
        guard !answers.isEmpty else { return 0 }
        return answers.reduce(0) { $0 + $1.scores.technical } / Double(answers.count)
    }
    
    var averagePace: Double {
        guard !answers.isEmpty else { return 0 }
        return answers.reduce(0) { $0 + $1.scores.pace } / Double(answers.count)
    }
    
    var totalFillerWords: Int {
        answers.reduce(0) { $0 + $1.metrics.fillerWordCount }
    }
    
    var totalWordCount: Int {
        answers.reduce(0) { $0 + $1.metrics.totalWordCount }
    }
    
    var averageSpeechRate: Double {
        guard !answers.isEmpty else { return 0 }
        return answers.reduce(0) { $0 + $1.metrics.speechRate } / Double(answers.count)
    }
    
    var averageSemanticSimilarity: Double {
        guard !answers.isEmpty else { return 0 }
        return answers.reduce(0) { $0 + $1.metrics.semanticSimilarity } / Double(answers.count)
    }
    
    init(answers: [Answer], questions: [Question]) {
        self.answers = answers
        self.questions = questions
    }
}
