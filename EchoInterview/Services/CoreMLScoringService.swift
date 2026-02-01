import CoreML
import os.log

final class CoreMLScoringService: ScoringProtocol {
    private let model: AnswerQualityModel
    private let fallbackService = SimpleScoringService()
    private static let logger = Logger(subsystem: "EchoInterview", category: "CoreMLScoringService")
    
    init() throws {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly
        self.model = try AnswerQualityModel(configuration: config)
        
        // Log model info for debugging
        Self.logger.info("CoreML Model loaded successfully")
        logModelDescription()
    }
    
    private func logModelDescription() {
        let description = model.model.modelDescription
        
        Self.logger.info("=== MODEL INPUT FEATURES ===")
        for (name, feature) in description.inputDescriptionsByName {
            Self.logger.info("Input: \(name) - Type: \(Self.featureTypeName(feature.type))")
        }
        
        Self.logger.info("=== MODEL OUTPUT FEATURES ===")
        for (name, feature) in description.outputDescriptionsByName {
            Self.logger.info("Output: \(name) - Type: \(Self.featureTypeName(feature.type))")
        }
    }
    
    private static func featureTypeName(_ type: MLFeatureType) -> String {
        switch type {
        case .invalid: return "invalid"
        case .int64: return "Int64"
        case .double: return "Double"
        case .string: return "String"
        case .image: return "Image"
        case .multiArray: return "MultiArray"
        case .dictionary: return "Dictionary"
        case .sequence: return "Sequence"
        @unknown default: return "unknown"
        }
    }
    
    func calculateScores(metrics: NLPMetrics, transcript: String) throws -> AnswerScores {
        // Validate and sanitize inputs
        let keywordCoverage = sanitize(metrics.keywordCoverage, min: 0, max: 1)
        let fillerRatio = sanitize(metrics.fillerRatio, min: 0, max: 1)
        let sentenceCount = max(1, metrics.sentenceCount)
        let avgSentenceLength = sanitize(metrics.avgSentenceLength, min: 1, max: 100)
        let semanticSimilarity = sanitize(metrics.semanticSimilarity, min: 0, max: 1)
        let speechRate = max(1, Int(metrics.speechRate))
        let pauseCount = max(0, metrics.pauseCount)
        
        Self.logger.debug("""
            CoreML Input - keyword_coverage: \(keywordCoverage), filler_ratio: \(fillerRatio), \
            sentence_count: \(sentenceCount), avg_sentence_length: \(avgSentenceLength), \
            semantic_similarity: \(semanticSimilarity), speech_rate: \(speechRate), \
            pause_count: \(pauseCount)
            """)
        
        do {
            let input = AnswerQualityModelInput(
                keyword_coverage: keywordCoverage,
                filler_ratio: fillerRatio,
                sentence_count: Int64(sentenceCount),
                avg_sentence_length: avgSentenceLength,
                semantic_similarity: semanticSimilarity,
                speech_rate: Int64(speechRate),
                pause_count: Int64(pauseCount)
            )
            
            let output = try model.prediction(input: input)
            var overall = sanitize(output.score, min: 0, max: 100)
            
            // POST-PROCESSING PENALTIES (stricter scoring)
            
            // 1. Extreme speech rate penalty
            if speechRate > 250 {
                let speedPenalty = Double(speechRate - 250) / 10  // -1 point per 10 wpm over 250
                overall -= speedPenalty
            } else if speechRate < 80 {
                let slowPenalty = Double(80 - speechRate) / 5  // -1 point per 5 wpm under 80
                overall -= slowPenalty
            }
            
            // 2. High filler ratio penalty (harsh on filler-heavy answers)
            if fillerRatio > 0.2 {
                let fillerPenalty = (fillerRatio - 0.2) * 100  // -10 points for every 10% over 20%
                overall -= fillerPenalty
            }
            
            // 3. Very short answer penalty
            if metrics.totalWordCount < 15 {
                overall -= Double(15 - metrics.totalWordCount) * 2  // -2 points per missing word
            }
            
            // 4. Low keyword coverage with low similarity = off-topic
            if keywordCoverage < 0.2 && semanticSimilarity < 0.5 {
                overall -= 15  // Off-topic penalty
            }
            
            // 5. Cap at 95 unless exceptional (prevents easy 100s)
            if overall > 95 && semanticSimilarity < 0.95 {
                overall = 95
            }
            
            overall = sanitize(overall, min: 0, max: 100)
            
            let clarity = calculateClarity(metrics)
            let confidence = calculateConfidence(metrics, overall: overall)
            let technical = calculateTechnical(metrics)
            let pace = calculatePace(metrics)
            
            // Calculate penalties for debug
            let rawScore = output.score
            var speedPenalty = 0.0
            var fillerPenalty = 0.0
            var shortPenalty = 0.0
            var offTopicPenalty = 0.0
            var cap95Applied = false
            
            if speechRate > 250 { speedPenalty = Double(speechRate - 250) / 10 }
            else if speechRate < 80 { speedPenalty = Double(80 - speechRate) / 5 }
            if fillerRatio > 0.2 { fillerPenalty = (fillerRatio - 0.2) * 100 }
            if metrics.totalWordCount < 15 { shortPenalty = Double(15 - metrics.totalWordCount) * 2 }
            if keywordCoverage < 0.2 && semanticSimilarity < 0.5 { offTopicPenalty = 15 }
            if rawScore > 95 && semanticSimilarity < 0.95 { cap95Applied = true }
            
            // Detailed debug output
            print("""
            
            ════════════════════════════════════════════════════════════
            📊 SCORING DEBUG
            ════════════════════════════════════════════════════════════
            
            INPUT METRICS:
            ├── keyword_coverage:    \(String(format: "%.2f", keywordCoverage)) (0=none, 1=many tech words)
            ├── filler_ratio:        \(String(format: "%.2f", fillerRatio)) (0=none, 1=all fillers)
            ├── sentence_count:      \(sentenceCount)
            ├── avg_sentence_length: \(String(format: "%.1f", avgSentenceLength)) words
            ├── semantic_similarity: \(String(format: "%.2f", semanticSimilarity)) (0=unrelated, 1=perfect match)
            ├── speech_rate:         \(speechRate) wpm (ideal: 120-180)
            ├── word_count:          \(metrics.totalWordCount)
            └── pause_count:         \(pauseCount)
            
            COREML RAW SCORE:        \(String(format: "%.1f", rawScore))
            
            POST-PROCESSING PENALTIES:
            ├── speed penalty:       \(speedPenalty > 0 ? "-" : "")\(String(format: "%.1f", speedPenalty)) \(speechRate > 250 ? "(too fast)" : speechRate < 80 ? "(too slow)" : "(ok)")
            ├── filler penalty:      \(fillerPenalty > 0 ? "-" : "")\(String(format: "%.1f", fillerPenalty)) \(fillerRatio > 0.2 ? "(>\(Int(fillerRatio*100))% fillers!)" : "(ok)")
            ├── short answer penalty:-\(String(format: "%.1f", shortPenalty)) \(metrics.totalWordCount < 15 ? "(<15 words)" : "(ok)")
            ├── off-topic penalty:   -\(String(format: "%.1f", offTopicPenalty)) \(offTopicPenalty > 0 ? "(low keywords + similarity)" : "(ok)")
            └── capped at 95:        \(cap95Applied ? "YES (need 95%+ similarity for 100)" : "no")
            
            CALCULATED SUB-SCORES:
            ├── clarity:             \(String(format: "%.1f", clarity))
            ├── confidence:          \(String(format: "%.1f", confidence))
            ├── technical:           \(String(format: "%.1f", technical))
            └── pace:                \(String(format: "%.1f", pace))
            
            ═══════════════════════════════════════════════════════════
            FINAL OVERALL:           \(String(format: "%.1f", overall))
            ════════════════════════════════════════════════════════════
            
            """)
            
            return AnswerScores(
                overall: overall,
                clarity: clarity,
                confidence: confidence,
                technical: technical,
                pace: pace
            )
        } catch {
            Self.logger.error("=== COREML PREDICTION FAILED ===")
            Self.logger.error("Error: \(error.localizedDescription)")
            Self.logger.error("Input values: kw=\(keywordCoverage), filler=\(fillerRatio), sent=\(sentenceCount), avgLen=\(avgSentenceLength), sim=\(semanticSimilarity), rate=\(speechRate), pause=\(pauseCount)")
            Self.logger.error("Using fallback SimpleScoringService")
            
            // Fall back to simple scoring
            return try fallbackService.calculateScores(metrics: metrics)
        }
    }
    
    // Conformance to protocol without transcript (uses empty string)
    func calculateScores(metrics: NLPMetrics) throws -> AnswerScores {
        try calculateScores(metrics: metrics, transcript: "")
    }
    
    private func sanitize(_ value: Double, min: Double, max: Double) -> Double {
        guard value.isFinite else { return min }
        return Swift.min(Swift.max(value, min), max)
    }
    
    private func calculateClarity(_ metrics: NLPMetrics) -> Double {
        let fillerPenalty = metrics.fillerRatio
        return max(0, (1.0 - fillerPenalty) * 100)
    }
    
    private func calculateConfidence(_ metrics: NLPMetrics, overall: Double) -> Double {
        // Base confidence on overall score and filler usage
        let fillerScore = 1.0 - min(Double(metrics.fillerWordCount) / 10.0, 1.0)
        let baseConfidence = (overall / 100) * 0.6 + fillerScore * 0.4
        return baseConfidence * 100
    }
    
    private func calculateTechnical(_ metrics: NLPMetrics) -> Double {
        // Technical score based on keyword coverage and semantic similarity
        let keywordContribution = metrics.keywordCoverage * 50
        let semanticContribution = metrics.semanticSimilarity * 50
        return min(keywordContribution + semanticContribution, 100)
    }
    
    private func calculatePace(_ metrics: NLPMetrics) -> Double {
        let idealRate = 150.0
        guard metrics.speechRate > 0 else { return 50 }
        let deviation = abs(metrics.speechRate - idealRate) / idealRate
        return max(0, (1.0 - deviation)) * 100
    }
}

enum CoreMLScoringError: Error {
    case modelNotAvailable
    case predictionFailed
}
