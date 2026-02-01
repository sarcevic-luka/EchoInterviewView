import AVFoundation
import os.log

actor AudioServiceImpl: AudioService {
    private let audioEngine = AVAudioEngine()
    private var isRecording = false
    private var bufferContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation?
    private static let logger = Logger(subsystem: "EchoInterview", category: "AudioService")
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func setupAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        Self.logger.info("Audio session configured: \(session.sampleRate) Hz")
    }
    
    func startRecording() async throws -> AsyncStream<AVAudioPCMBuffer> {
        guard !isRecording else {
            throw AudioServiceError.alreadyRecording
        }
        
        try await setupAudioSession()
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        Self.logger.info("Audio format: \(format.sampleRate) Hz, \(format.channelCount) channels")
        
        let (stream, continuation) = AsyncStream<AVAudioPCMBuffer>.makeStream()
        bufferContinuation = continuation
        
        // Larger buffer for better speech recognition
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            Task {
                await self.handleBuffer(buffer)
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        Self.logger.info("Recording started")
        
        return stream
    }
    
    func stopRecording() async {
        guard isRecording else { return }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        bufferContinuation?.finish()
        bufferContinuation = nil
        isRecording = false
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func handleBuffer(_ buffer: AVAudioPCMBuffer) {
        bufferContinuation?.yield(buffer)
    }
}

enum AudioServiceError: Error {
    case alreadyRecording
    case audioSessionSetupFailed
}
