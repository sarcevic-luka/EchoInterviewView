import AVFoundation
import Speech

protocol SpeechRecognitionService: Actor {
    func requestAuthorization() async -> Bool
    func startRecognition(audioStream: AsyncStream<AVAudioPCMBuffer>) async throws -> AsyncStream<String>
    func stopRecognition() async -> String
}

actor SpeechRecognitionServiceImpl: SpeechRecognitionService {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var transcriptContinuation: AsyncStream<String>.Continuation?
    private var finalTranscript: String = ""
    private var recognitionStreamTask: Task<Void, Never>?
    
    init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func startRecognition(audioStream: AsyncStream<AVAudioPCMBuffer>) async throws -> AsyncStream<String> {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        finalTranscript = ""
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        recognitionRequest = request
        
        let (stream, continuation) = AsyncStream<String>.makeStream()
        transcriptContinuation = continuation
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            
            Task {
                await self.handleRecognitionResult(result: result, error: error)
            }
        }
        
        recognitionStreamTask = Task {
            for await buffer in audioStream {
                guard !Task.isCancelled else { break }
                recognitionRequest?.append(buffer)
            }
            recognitionRequest?.endAudio()
        }
        
        return stream
    }
    
    func stopRecognition() async -> String {
        recognitionStreamTask?.cancel()
        recognitionStreamTask = nil
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionTask = nil
        recognitionRequest = nil
        transcriptContinuation?.finish()
        transcriptContinuation = nil
        
        return finalTranscript
    }
    
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            let transcript = result.bestTranscription.formattedString
            finalTranscript = transcript
            transcriptContinuation?.yield(transcript)
            
            if result.isFinal {
                transcriptContinuation?.finish()
            }
        }
        
        if error != nil {
            transcriptContinuation?.finish()
        }
    }
}

enum SpeechRecognitionError: Error {
    case recognizerUnavailable
    case notAuthorized
}
