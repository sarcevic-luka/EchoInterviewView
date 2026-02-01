import Foundation

// MARK: - Audio Errors

enum AudioError: LocalizedError {
    case microphonePermissionDenied
    case audioSessionSetupFailed(underlying: Error)
    case recordingFailed(underlying: Error)
    case noAudioInput
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is required to record your answers."
        case .audioSessionSetupFailed:
            return "Failed to set up audio. Please try again."
        case .recordingFailed:
            return "Recording failed. Please check your microphone."
        case .noAudioInput:
            return "No audio input detected. Please check your microphone."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Open Settings to grant microphone access."
        case .audioSessionSetupFailed, .recordingFailed:
            return "Try closing other apps using the microphone."
        case .noAudioInput:
            return "Make sure your device's microphone is not blocked."
        }
    }
}

// MARK: - Speech Recognition Errors

enum SpeechError: LocalizedError {
    case recognitionPermissionDenied
    case recognizerUnavailable
    case recognitionFailed(underlying: Error)
    case noSpeechDetected
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .recognitionPermissionDenied:
            return "Speech recognition access is required to transcribe your answers."
        case .recognizerUnavailable:
            return "Speech recognition is not available on this device."
        case .recognitionFailed:
            return "Failed to recognize speech. Please try again."
        case .noSpeechDetected:
            return "No speech was detected. Please speak clearly."
        case .timeout:
            return "Speech recognition timed out. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .recognitionPermissionDenied:
            return "Open Settings to grant speech recognition access."
        case .recognizerUnavailable:
            return "Speech recognition requires iOS 17 or later."
        case .recognitionFailed, .timeout:
            return "Make sure you're in a quiet environment."
        case .noSpeechDetected:
            return "Speak closer to the microphone and try again."
        }
    }
}

// MARK: - Scoring Errors

enum ScoringError: LocalizedError {
    case modelLoadFailed
    case predictionFailed(underlying: Error)
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .modelLoadFailed:
            return "Failed to load the scoring model."
        case .predictionFailed:
            return "Failed to analyze your answer."
        case .invalidInput:
            return "Invalid input for scoring."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelLoadFailed:
            return "Please restart the app."
        case .predictionFailed, .invalidInput:
            return "Try recording your answer again."
        }
    }
}

// MARK: - Persistence Errors

enum PersistenceError: LocalizedError {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save your session."
        case .fetchFailed:
            return "Failed to load your history."
        case .deleteFailed:
            return "Failed to delete the session."
        case .encodingFailed:
            return "Failed to prepare data for saving."
        case .decodingFailed:
            return "Failed to read saved data."
        }
    }
    
    var recoverySuggestion: String? {
        "Please try again. If the problem persists, restart the app."
    }
}

// MARK: - LLM Errors

enum LLMError: LocalizedError {
    case sessionInitializationFailed
    case generationFailed(underlying: Error)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .sessionInitializationFailed:
            return "AI features are not available."
        case .generationFailed:
            return "Failed to generate content."
        case .invalidResponse:
            return "Received an invalid response."
        }
    }
    
    var recoverySuggestion: String? {
        "The app will use fallback content instead."
    }
}

// MARK: - General App Errors

enum AppError: LocalizedError {
    case unknown(underlying: Error?)
    case networkUnavailable
    case permissionRequired(type: String)
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unexpected error occurred."
        case .networkUnavailable:
            return "No network connection available."
        case .permissionRequired(let type):
            return "\(type) permission is required."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unknown:
            return "Please try again or restart the app."
        case .networkUnavailable:
            return "Check your internet connection."
        case .permissionRequired:
            return "Open Settings to grant the required permission."
        }
    }
}
