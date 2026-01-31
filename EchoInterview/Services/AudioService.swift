import AVFoundation

protocol AudioService: Actor {
    func requestMicrophonePermission() async -> Bool
    func setupAudioSession() async throws
    func startRecording() async throws -> AsyncStream<AVAudioPCMBuffer>
    func stopRecording() async
}
