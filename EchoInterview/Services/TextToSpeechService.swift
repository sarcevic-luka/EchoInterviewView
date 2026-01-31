import AVFoundation

protocol TextToSpeechService: Actor {
    func speak(_ text: String) async throws
    func stop() async
}

actor TextToSpeechServiceImpl: TextToSpeechService {
    private let synthesizer: AVSpeechSynthesizer
    private let delegate: SpeechDelegate
    private var speakContinuation: CheckedContinuation<Void, Error>?
    
    init() {
        self.synthesizer = AVSpeechSynthesizer()
        self.delegate = SpeechDelegate()
        self.synthesizer.delegate = delegate
    }
    
    func speak(_ text: String) async throws {
        try await setupAudioSessionForPlayback()
        
        delegate.onFinish = { [weak self] in
            Task { await self?.handleSpeechFinished() }
        }
        
        delegate.onCancel = { [weak self] in
            Task { await self?.handleSpeechCancelled() }
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            speakContinuation = continuation
            synthesizer.speak(utterance)
        }
    }
    
    func stop() async {
        synthesizer.stopSpeaking(at: .immediate)
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
