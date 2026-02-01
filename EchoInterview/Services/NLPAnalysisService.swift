import NaturalLanguage

final class NLPAnalysisService {
    private let fillerWords: Set<String> = [
        "um", "uh", "like", "you know", "sort of", "kind of"
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
        
        return NLPMetrics(
            totalWordCount: totalWordCount,
            fillerWordCount: fillerWordCount,
            speechRate: speechRate,
            semanticSimilarity: semanticSimilarity
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
        let singleWordFillers: Set<String> = ["um", "uh", "like"]
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
}
