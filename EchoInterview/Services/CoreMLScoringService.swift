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
            let overall = sanitize(output.score, min: 0, max: 100)
            
            Self.logger.debug("CoreML prediction successful, overall score: \(overall)")
            
            let clarity = calculateClarity(metrics)
            let confidence = calculateConfidence(metrics, overall: overall)
            let technical = calculateTechnical(metrics)
            let pace = calculatePace(metrics)
            
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
