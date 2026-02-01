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
        
        // Get the hardware format and create a compatible recording format
        let hardwareFormat = inputNode.inputFormat(forBus: 0)
        Self.logger.info("Hardware format: \(hardwareFormat.sampleRate) Hz, \(hardwareFormat.channelCount) channels")
        
        // Use nil format to let the system choose the best format
        // This avoids format mismatch errors
        let recordingFormat: AVAudioFormat?
        if hardwareFormat.sampleRate > 0 && hardwareFormat.channelCount > 0 {
            recordingFormat = hardwareFormat
        } else {
            // Fallback: create a standard format
            recordingFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
        }
        
        Self.logger.info("Recording format: \(recordingFormat?.sampleRate ?? 0) Hz, \(recordingFormat?.channelCount ?? 0) channels")
        
        let (stream, continuation) = AsyncStream<AVAudioPCMBuffer>.makeStream()
        bufferContinuation = continuation
        
        // Install tap with the compatible format
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
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
