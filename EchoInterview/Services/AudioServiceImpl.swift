import AVFoundation

actor AudioServiceImpl: AudioService {
    private let audioEngine = AVAudioEngine()
    private var isRecording = false
    private var bufferContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation?
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func setupAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
        try session.setActive(true)
    }
    
    func startRecording() async throws -> AsyncStream<AVAudioPCMBuffer> {
        guard !isRecording else {
            throw AudioServiceError.alreadyRecording
        }
        
        try await setupAudioSession()
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        let stream = AsyncStream<AVAudioPCMBuffer> { continuation in
            self.bufferContinuation = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.stopRecording()
                }
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            Task {
                await self.handleBuffer(buffer)
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        
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
