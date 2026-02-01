import Foundation
import SwiftData
import os.log

@MainActor
@Observable
final class HistoryViewModel {
    private let persistenceService: PersistenceService
    private let logger = Logger(subsystem: "EchoInterview", category: "HistoryViewModel")
    
    private(set) var sessions: [InterviewSessionEntity] = []
    private(set) var isLoading = false
    var errorMessage: String?
    
    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
    }
    
    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            sessions = try await persistenceService.fetchAllSessions()
            logger.info("Loaded \(self.sessions.count) sessions")
        } catch {
            logger.error("Failed to load sessions: \(error.localizedDescription)")
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }
    }
    
    func deleteSession(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let session = sessions[index]
                do {
                    try await persistenceService.deleteSession(id: session.id)
                    sessions.remove(at: index)
                    logger.info("Deleted session: \(session.id)")
                } catch {
                    logger.error("Failed to delete session: \(error.localizedDescription)")
                    errorMessage = "Failed to delete session"
                }
            }
        }
    }
    
    func deleteSession(_ session: InterviewSessionEntity) {
        Task {
            do {
                try await persistenceService.deleteSession(id: session.id)
                sessions.removeAll { $0.id == session.id }
                logger.info("Deleted session: \(session.id)")
            } catch {
                logger.error("Failed to delete session: \(error.localizedDescription)")
                errorMessage = "Failed to delete session"
            }
        }
    }
}
