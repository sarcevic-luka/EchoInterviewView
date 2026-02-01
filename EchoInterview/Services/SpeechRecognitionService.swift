import AVFoundation
import Speech
import os.log

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
    private var accumulatedTranscript: String = ""
    private var currentSegmentTranscript: String = ""
    private var recognitionStreamTask: Task<Void, Never>?
    private var isListening: Bool = false
    private var currentTaskId: Int = 0
    private var lastSegmentCount: Int = 0  // Track segment count to detect restarts
    private static let logger = Logger(subsystem: "EchoInterview", category: "SpeechRecognition")
    
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
        
        // Reset state for new recording session
        accumulatedTranscript = ""
        currentSegmentTranscript = ""
        currentTaskId = 0
        lastSegmentCount = 0
        isListening = true
        
        let (stream, continuation) = AsyncStream<String>.makeStream()
        transcriptContinuation = continuation
        
        // Start the recognition task
        startNewRecognitionTask()
        
        Self.logger.info("Starting speech recognition")
        
        // Process audio buffers
        recognitionStreamTask = Task {
            var bufferCount = 0
            for await buffer in audioStream {
                guard !Task.isCancelled, isListening else { break }
                recognitionRequest?.append(buffer)
                bufferCount += 1
            }
            Self.logger.debug("Audio stream ended after \(bufferCount) buffers")
            recognitionRequest?.endAudio()
        }
        
        return stream
    }
    
    private func startNewRecognitionTask() {
        guard let speechRecognizer, isListening else { return }
        
        // Increment task ID to ignore callbacks from old tasks
        currentTaskId += 1
        let taskId = currentTaskId
        
        // Reset segment count for new task
        lastSegmentCount = 0
        
        // Create new request FIRST before canceling old one (prevents buffer loss)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.addsPunctuation = true
        
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        // Atomically swap the request
        let oldTask = recognitionTask
        recognitionRequest = request
        oldTask?.cancel()
        
        Self.logger.debug("Started task #\(taskId) (accumulated: \(self.accumulatedTranscript.count) chars)")
        
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            
            Task {
                await self.handleRecognitionResult(result: result, error: error, taskId: taskId)
            }
        }
    }
    
    func stopRecognition() async -> String {
        // Mark as not listening FIRST to prevent restarts
        isListening = false
        
        // Combine accumulated transcript with current segment
        let fullTranscript = buildFullTranscript()
        Self.logger.info("USER stopped recognition, full transcript: \(fullTranscript.prefix(100))...")
        
        recognitionStreamTask?.cancel()
        recognitionStreamTask = nil
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        transcriptContinuation?.finish()
        transcriptContinuation = nil
        
        return fullTranscript
    }
    
    private func buildFullTranscript() -> String {
        if accumulatedTranscript.isEmpty {
            return currentSegmentTranscript
        } else if currentSegmentTranscript.isEmpty {
            return accumulatedTranscript
        } else {
            return accumulatedTranscript + " " + currentSegmentTranscript
        }
    }
    
    private func handleRecognitionResult(result: SFSpeechRecognitionResult?, error: Error?, taskId: Int) {
        // Ignore callbacks from old/cancelled tasks
        guard taskId == currentTaskId else {
            Self.logger.debug("Ignoring callback from old task #\(taskId) (current: \(self.currentTaskId))")
            return
        }
        
        // Ignore results if we've stopped listening
        guard isListening else { return }
        
        if let result {
            let segmentTranscript = result.bestTranscription.formattedString
            let segmentCount = result.bestTranscription.segments.count
            
            Self.logger.debug("Task #\(taskId): \(segmentCount) segments, isFinal: \(result.isFinal)")
            
            // CRITICAL FIX: Detect when segment count drops (recognizer internal restart)
            // This happens when the recognizer loses context after a pause, BEFORE isFinal
            if segmentCount < lastSegmentCount && !currentSegmentTranscript.isEmpty {
                Self.logger.info("⚠️ Segment count dropped (\(self.lastSegmentCount) → \(segmentCount)), accumulating: '\(self.currentSegmentTranscript.prefix(50))...'")
                
                // Save the current segment before it's lost
                if accumulatedTranscript.isEmpty {
                    accumulatedTranscript = currentSegmentTranscript
                } else {
                    accumulatedTranscript += " " + currentSegmentTranscript
                }
                
                Self.logger.info("✅ Total accumulated after drop: '\(self.accumulatedTranscript.prefix(100))...'")
                currentSegmentTranscript = ""
            }
            
            // Update segment count tracking
            lastSegmentCount = segmentCount
            
            // Update current segment
            currentSegmentTranscript = segmentTranscript
            
            // Yield the full accumulated transcript (this is what the ViewModel sees!)
            let fullTranscript = buildFullTranscript()
            transcriptContinuation?.yield(fullTranscript)
            
            if result.isFinal {
                // Recognition auto-stopped (silence) - save segment and restart
                Self.logger.info("Task #\(taskId) finished (isFinal), accumulating: '\(segmentTranscript.prefix(50))...'")
                
                if !segmentTranscript.isEmpty {
                    if accumulatedTranscript.isEmpty {
                        accumulatedTranscript = segmentTranscript
                    } else {
                        accumulatedTranscript += " " + segmentTranscript
                    }
                }
                
                currentSegmentTranscript = ""
                lastSegmentCount = 0  // Reset for next task
                
                Self.logger.info("✅ Total accumulated after isFinal: '\(self.accumulatedTranscript.prefix(100))...'")
                
                // RESTART recognition to keep listening
                if isListening {
                    startNewRecognitionTask()
                }
            }
        }
        
        if let error {
            Self.logger.error("Task #\(taskId) error: \(error.localizedDescription)")
            // Only restart on error if this is the current task and still listening
            if taskId == currentTaskId, isListening {
                startNewRecognitionTask()
            }
        }
    }
}

enum SpeechRecognitionError: Error {
    case recognizerUnavailable
    case notAuthorized
}
