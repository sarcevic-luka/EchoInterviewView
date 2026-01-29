import Foundation

protocol SpeechServiceProtocol {
    func requestMicrophonePermission() async -> Bool
    func requestSpeechRecognitionPermission() async -> Bool
    func startRecording() async throws
    func stopRecording() async throws
}

struct SpeechService: SpeechServiceProtocol {
    init() {}
    
    func requestMicrophonePermission() async -> Bool {
        return false
    }
    
    func requestSpeechRecognitionPermission() async -> Bool {
        return false
    }
    
    func startRecording() async throws {
    }
    
    func stopRecording() async throws {
    }
}

