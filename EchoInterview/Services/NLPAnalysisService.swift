import NaturalLanguage

final class NLPAnalysisService {
    private let fillerWords: Set<String> = [
        "um", "uh", "like", "you know", "sort of", "kind of"
    ]
    
    private let technicalKeywords: Set<String> = [
        "swift", "swiftui", "ios", "app", "mobile", "api", "database", "server",
        "architecture", "mvvm", "mvc", "design", "pattern", "test", "testing",
        "performance", "optimization", "algorithm", "data", "structure", "code",
        "programming", "development", "agile", "scrum", "git", "deploy", "ci",
        "cd", "framework", "library", "sdk", "xcode", "debug", "feature",
        "project", "team", "collaboration", "problem", "solution", "challenge",
        "implement", "build", "create", "develop", "integrate", "scale"
    ]
    
    private let idealAnswer = """
        I built a mobile app using Swift and SwiftUI. The main challenge was state management \
        across multiple screens. I solved it by implementing MVVM with Combine for reactive updates.
        """
    
    private lazy var sentenceEmbedding: NLEmbedding? = {
        NLEmbedding.sentenceEmbedding(for: .english)
    }()
    
    func analyze(transcript: String, duration: TimeInterval) -> NLPMetrics {
        let words = tokenizeWords(from: transcript)
        let totalWordCount = words.count
        let fillerWordCount = countFillerWords(in: transcript.lowercased(), words: words)
        let speechRate = duration > 0 ? Double(totalWordCount) / (duration / 60.0) : 0
        let semanticSimilarity = calculateSemanticSimilarity(transcript: transcript)
        let sentenceCount = countSentences(in: transcript)
        let pauseCount = estimatePauseCount(transcript: transcript, duration: duration, wordCount: totalWordCount)
        let keywordCoverage = calculateKeywordCoverage(words: words)
        
        return NLPMetrics(
            totalWordCount: totalWordCount,
            fillerWordCount: fillerWordCount,
            speechRate: speechRate,
            semanticSimilarity: semanticSimilarity,
            sentenceCount: sentenceCount,
            pauseCount: pauseCount,
            keywordCoverage: keywordCoverage
        )
    }
    
    // MARK: - Semantic Similarity
    
    private func calculateSemanticSimilarity(transcript: String) -> Double {
        guard let embedding = sentenceEmbedding else {
            return 0
        }
        
        guard let transcriptVector = embedding.vector(for: transcript),
              let idealVector = embedding.vector(for: idealAnswer) else {
            return 0
        }
        
        return cosineSimilarity(transcriptVector, idealVector)
    }
    
    private func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        guard vectorA.count == vectorB.count, !vectorA.isEmpty else {
            return 0
        }
        
        var dotProduct: Double = 0
        var magnitudeA: Double = 0
        var magnitudeB: Double = 0
        
        for i in 0..<vectorA.count {
            dotProduct += vectorA[i] * vectorB[i]
            magnitudeA += vectorA[i] * vectorA[i]
            magnitudeB += vectorB[i] * vectorB[i]
        }
        
        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)
        guard magnitude > 0 else { return 0 }
        
        // Normalize to 0-1 range (cosine similarity is -1 to 1)
        let similarity = dotProduct / magnitude
        return (similarity + 1) / 2
    }
    
    // MARK: - Word Tokenization
    
    private func tokenizeWords(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        var words: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range])
            words.append(word)
            return true
        }
        
        return words
    }
    
    // MARK: - Filler Word Detection
    
    private func countFillerWords(in lowercasedText: String, words: [String]) -> Int {
        var count = 0
        
        // Count single-word fillers
        let singleWordFillers: Set<String> = ["um", "uh", "like", "basically"]
        for word in words {
            if singleWordFillers.contains(word.lowercased()) {
                count += 1
            }
        }
        
        // Count multi-word fillers
        let multiWordFillers = ["you know", "sort of", "kind of"]
        for filler in multiWordFillers {
            var searchRange = lowercasedText.startIndex..<lowercasedText.endIndex
            while let range = lowercasedText.range(of: filler, range: searchRange) {
                count += 1
                searchRange = range.upperBound..<lowercasedText.endIndex
            }
        }
        
        return count
    }
    
    // MARK: - Sentence Detection
    
    private func countSentences(in text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var count = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            count += 1
            return true
        }
        
        return max(count, 1)
    }
    
    // MARK: - Pause Estimation
    
    private func estimatePauseCount(transcript: String, duration: TimeInterval, wordCount: Int) -> Int {
        guard duration > 0, wordCount > 0 else { return 0 }
        
        // Estimate pauses based on speech rate deviation from ideal
        // Ideal speech rate: ~150 wpm
        // If speaking slower, likely more pauses
        let actualRate = Double(wordCount) / (duration / 60.0)
        let idealRate = 150.0
        
        // Count punctuation-based pauses (commas, periods indicate natural pauses)
        let punctuationPauses = transcript.filter { $0 == "," || $0 == "." || $0 == ";" }.count
        
        // Estimate additional pauses if speaking slower than ideal
        let ratePauses: Int
        if actualRate < idealRate {
            let slowdownFactor = (idealRate - actualRate) / idealRate
            ratePauses = Int(slowdownFactor * Double(wordCount) / 10)
        } else {
            ratePauses = 0
        }
        
        return punctuationPauses + ratePauses
    }
    
    // MARK: - Keyword Coverage
    
    private func calculateKeywordCoverage(words: [String]) -> Double {
        guard !words.isEmpty else { return 0 }
        
        let lowercasedWords = Set(words.map { $0.lowercased() })
        let matchedKeywords = technicalKeywords.intersection(lowercasedWords)
        
        // Coverage is ratio of matched keywords to a reasonable expectation (e.g., 5 keywords)
        let expectedKeywords = 5.0
        let coverage = Double(matchedKeywords.count) / expectedKeywords
        
        return min(coverage, 1.0)
    }
}
