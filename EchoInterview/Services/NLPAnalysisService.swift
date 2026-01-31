import NaturalLanguage

final class NLPAnalysisService {
    private let fillerWords: Set<String> = [
        "um", "uh", "like", "you know", "sort of", "kind of"
    ]
    
    func analyze(transcript: String, duration: TimeInterval) -> NLPMetrics {
        let words = tokenizeWords(from: transcript)
        let totalWordCount = words.count
        let fillerWordCount = countFillerWords(in: transcript.lowercased(), words: words)
        let speechRate = duration > 0 ? Double(totalWordCount) / (duration / 60.0) : 0
        
        return NLPMetrics(
            totalWordCount: totalWordCount,
            fillerWordCount: fillerWordCount,
            speechRate: speechRate
        )
    }
    
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
