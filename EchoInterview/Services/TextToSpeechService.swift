import AVFoundation

protocol TextToSpeechService: Actor {
    func speak(_ text: String) async throws
    func stop() async
}

actor TextToSpeechServiceImpl: TextToSpeechService {
    private let synthesizer: AVSpeechSynthesizer
    private let delegate: SpeechDelegate
    private var speakContinuation: CheckedContinuation<Void, Error>?
    
    private enum UserDefaultsKeys {
        static let voiceIdentifier = "settings.voiceIdentifier"
        static let speechRate = "settings.speechRate"
    }
    
    init() {
        self.synthesizer = AVSpeechSynthesizer()
        self.delegate = SpeechDelegate()
        self.synthesizer.delegate = delegate
    }
    
    func speak(_ text: String) async throws {
        // Cancel any ongoing speech first
        if speakContinuation != nil {
            synthesizer.stopSpeaking(at: .immediate)
            speakContinuation?.resume(throwing: TextToSpeechError.cancelled)
            speakContinuation = nil
        }
        
        try await setupAudioSessionForPlayback()
        
        delegate.onFinish = { [weak self] in
            Task { await self?.handleSpeechFinished() }
        }
        
        delegate.onCancel = { [weak self] in
            Task { await self?.handleSpeechCancelled() }
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Load voice preference from UserDefaults
        let defaults = UserDefaults.standard
        if let voiceIdentifier = defaults.string(forKey: UserDefaultsKeys.voiceIdentifier),
           let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Load speech rate preference from UserDefaults
        if let savedRate = defaults.object(forKey: UserDefaultsKeys.speechRate) as? Float {
            utterance.rate = savedRate
        } else {
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.speakContinuation = continuation
            self.synthesizer.speak(utterance)
        }
    }
    
    func stop() async {
        if speakContinuation != nil {
            synthesizer.stopSpeaking(at: .immediate)
            speakContinuation?.resume(throwing: TextToSpeechError.cancelled)
            speakContinuation = nil
        }
    }
    
    private func setupAudioSessionForPlayback() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, options: .duckOthers)
        try session.setActive(true)
    }
    
    private func handleSpeechFinished() {
        speakContinuation?.resume()
        speakContinuation = nil
    }
    
    private func handleSpeechCancelled() {
        speakContinuation?.resume(throwing: TextToSpeechError.cancelled)
        speakContinuation = nil
    }
}

private final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    var onFinish: (() -> Void)?
    var onCancel: (() -> Void)?
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onCancel?()
    }
}

enum TextToSpeechError: Error {
    case cancelled
    case audioSessionFailed
}
