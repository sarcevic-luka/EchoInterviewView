import Foundation
import SwiftUI
import AVFoundation
import Speech
import os.log

@MainActor
@Observable
final class SettingsViewModel {
    private let persistenceService: PersistenceService?
    private let audioService: any AudioService
    private let speechService: any SpeechRecognitionService
    private let logger = Logger(subsystem: "EchoInterview", category: "SettingsViewModel")
    
    // Voice Settings
    var selectedVoiceIdentifier: String {
        didSet { saveVoicePreference() }
    }
    var speechRate: Float {
        didSet { saveSpeechRatePreference() }
    }
    
    // Permission Status
    private(set) var micPermissionStatus: PermissionStatus = .unknown
    private(set) var speechPermissionStatus: PermissionStatus = .unknown
    
    // Data
    private(set) var sessionCount: Int = 0
    var showClearHistoryConfirmation = false
    private(set) var isClearingHistory = false
    
    // Available Voices
    let availableVoices: [AVSpeechSynthesisVoice]
    
    enum PermissionStatus {
        case unknown
        case granted
        case denied
        
        var displayText: String {
            switch self {
            case .unknown: return "Unknown"
            case .granted: return "Granted"
            case .denied: return "Denied"
            }
        }
        
        var iconName: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .granted: return "checkmark.circle.fill"
            case .denied: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .unknown: return .secondary
            case .granted: return .green
            case .denied: return .red
            }
        }
    }
    
    private enum UserDefaultsKeys {
        static let voiceIdentifier = "settings.voiceIdentifier"
        static let speechRate = "settings.speechRate"
    }
    
    init(
        persistenceService: PersistenceService? = nil,
        audioService: any AudioService = AudioServiceImpl(),
        speechService: any SpeechRecognitionService = SpeechRecognitionServiceImpl()
    ) {
        self.persistenceService = persistenceService
        self.audioService = audioService
        self.speechService = speechService
        
        // Load available English voices
        self.availableVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.name < $1.name }
        
        // Load saved preferences
        let defaults = UserDefaults.standard
        self.selectedVoiceIdentifier = defaults.string(forKey: UserDefaultsKeys.voiceIdentifier) 
            ?? AVSpeechSynthesisVoice(language: "en-US")?.identifier 
            ?? ""
        self.speechRate = defaults.object(forKey: UserDefaultsKeys.speechRate) as? Float 
            ?? AVSpeechUtteranceDefaultSpeechRate
    }
    
    func loadPermissionStatus() async {
        // Check microphone permission
        let micGranted = await audioService.requestMicrophonePermission()
        micPermissionStatus = micGranted ? .granted : .denied
        
        // Check speech recognition permission
        let speechGranted = await speechService.requestAuthorization()
        speechPermissionStatus = speechGranted ? .granted : .denied
    }
    
    func loadSessionCount() async {
        guard let persistenceService else {
            sessionCount = 0
            return
        }
        
        do {
            let sessions = try await persistenceService.fetchAllSessions()
            sessionCount = sessions.count
        } catch {
            logger.error("Failed to load session count: \(error.localizedDescription)")
            sessionCount = 0
        }
    }
    
    func clearAllHistory() async {
        guard let persistenceService else { return }
        
        isClearingHistory = true
        defer { isClearingHistory = false }
        
        do {
            try await persistenceService.deleteAllSessions()
            sessionCount = 0
            logger.info("Cleared all history")
        } catch {
            logger.error("Failed to clear history: \(error.localizedDescription)")
        }
    }
    
    func voiceName(for identifier: String) -> String {
        availableVoices.first { $0.identifier == identifier }?.name ?? "Default"
    }
    
    private func saveVoicePreference() {
        UserDefaults.standard.set(selectedVoiceIdentifier, forKey: UserDefaultsKeys.voiceIdentifier)
        logger.debug("Saved voice preference: \(self.selectedVoiceIdentifier)")
    }
    
    private func saveSpeechRatePreference() {
        UserDefaults.standard.set(speechRate, forKey: UserDefaultsKeys.speechRate)
        logger.debug("Saved speech rate: \(self.speechRate)")
    }
}
