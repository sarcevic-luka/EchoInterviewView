import Foundation
import FoundationModels
import os.log

protocol LLMServiceProtocol: Sendable {
    func generateQuestion(context: [Question], interviewType: String) async -> String
    func generateFeedback(answer: Answer) async -> [String]
}

final class LLMService: LLMServiceProtocol, @unchecked Sendable {
    private var session: LanguageModelSession?
    private let logger = Logger(subsystem: "EchoInterview", category: "LLMService")
    
    private let fallbackQuestions = [
        "Tell me about a recent project you're proud of.",
        "Describe a technical challenge you faced and how you solved it.",
        "How do you prioritize tasks when working on multiple projects?",
        "Tell me about a time you had to learn a new technology quickly.",
        "Where do you see yourself in your career in 3 years?"
    ]
    
    private let fallbackTips = [
        "Practice reducing filler words like 'um' and 'uh'",
        "Structure answers using STAR method (Situation, Task, Action, Result)",
        "Aim for 30-60 second responses with clear examples"
    ]
    
    init() {
        do {
            self.session = try LanguageModelSession()
            logger.info("LLM session initialized successfully")
        } catch {
            logger.warning("LLM initialization failed: \(error.localizedDescription). Using fallback questions.")
            self.session = nil
        }
    }
    
    var isAvailable: Bool {
        session != nil
    }
    
    func generateQuestion(context: [Question], interviewType: String) async -> String {
        guard let session = session else {
            return fallbackQuestion(for: context.count)
        }
        
        let prompt = buildQuestionPrompt(context: context, interviewType: interviewType)
        
        do {
            let response = try await session.respond(to: prompt)
            let question = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            logger.debug("Generated question: \(question)")
            return question.isEmpty ? fallbackQuestion(for: context.count) : question
        } catch {
            logger.error("Question generation failed: \(error.localizedDescription)")
            return fallbackQuestion(for: context.count)
        }
    }
    
    func generateFeedback(answer: Answer) async -> [String] {
        guard let session = session else {
            return generateFallbackTips(for: answer)
        }
        
        let prompt = buildFeedbackPrompt(for: answer)
        
        do {
            let response = try await session.respond(to: prompt)
            let tips = parseTips(from: response.content)
            return tips.isEmpty ? generateFallbackTips(for: answer) : tips
        } catch {
            logger.error("Feedback generation failed: \(error.localizedDescription)")
            return generateFallbackTips(for: answer)
        }
    }
    
    // MARK: - Private Methods
    
    private func fallbackQuestion(for index: Int) -> String {
        guard index < fallbackQuestions.count else {
            return "Tell me more about your experience."
        }
        return fallbackQuestions[index]
    }
    
    private func generateFallbackTips(for answer: Answer) -> [String] {
        var tips: [String] = []
        
        if answer.metrics.fillerWordCount > 3 {
            tips.append("Try to reduce filler words like 'um', 'uh', and 'like' to sound more confident")
        }
        
        if answer.scores.clarity < 60 {
            tips.append("Structure your answer with a clear beginning, middle, and end")
        }
        
        if answer.scores.confidence < 60 {
            tips.append("Speak at a steady pace and avoid trailing off at the end of sentences")
        }
        
        if answer.duration < 15 {
            tips.append("Expand your answers with specific examples and details")
        } else if answer.duration > 120 {
            tips.append("Practice being more concise - aim for 30-60 second responses")
        }
        
        // Ensure we always return at least some tips
        if tips.isEmpty {
            tips = fallbackTips
        }
        
        return Array(tips.prefix(3))
    }
    
    private func buildQuestionPrompt(context: [Question], interviewType: String) -> String {
        let previousQuestions = context.isEmpty
            ? "None yet - this is the first question."
            : context.map { "- " + $0.text }.joined(separator: "\n")
        
        return """
        You are conducting a professional interview for a \(interviewType) position.
        
        Previous questions asked:
        \(previousQuestions)
        
        Generate the next interview question. Make it conversational, relevant, and non-repetitive.
        Respond with ONLY the question text, no preamble or explanation.
        """
    }
    
    private func buildFeedbackPrompt(for answer: Answer) -> String {
        """
        Analyze this interview answer:
        
        Transcript: "\(answer.transcript)"
        
        Scores:
        - Overall: \(Int(answer.scores.overall))/100
        - Clarity: \(Int(answer.scores.clarity))/100
        - Confidence: \(Int(answer.scores.confidence))/100
        
        Filler word count: \(answer.metrics.fillerWordCount)
        Duration: \(Int(answer.duration)) seconds
        
        Provide 3 specific, actionable coaching tips to improve this answer.
        Format as a JSON array of strings: ["tip1", "tip2", "tip3"]
        """
    }
    
    private func parseTips(from response: String) -> [String] {
        // Try to extract JSON array from response
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON array bounds
        guard let startIndex = trimmed.firstIndex(of: "["),
              let endIndex = trimmed.lastIndex(of: "]") else {
            return []
        }
        
        let jsonString = String(trimmed[startIndex...endIndex])
        
        guard let data = jsonString.data(using: .utf8),
              let tips = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        
        return tips
    }
}
