import SwiftData
import Foundation
import os.log

@ModelActor
actor PersistenceService {
    private static let logger = Logger(subsystem: "EchoInterview", category: "Persistence")
    
    func saveSession(_ entity: InterviewSessionEntity) throws {
        modelContext.insert(entity)
        try modelContext.save()
        Self.logger.info("Saved interview session: \(entity.id)")
    }
    
    func fetchAllSessions() throws -> [InterviewSessionEntity] {
        let descriptor = FetchDescriptor<InterviewSessionEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)
        Self.logger.debug("Fetched \(sessions.count) sessions")
        return sessions
    }
    
    func deleteSession(id: UUID) throws {
        let descriptor = FetchDescriptor<InterviewSessionEntity>(
            predicate: #Predicate { $0.id == id }
        )
        if let entity = try modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            try modelContext.save()
            Self.logger.info("Deleted session: \(id)")
        }
    }
    
    func deleteAllSessions() throws {
        let descriptor = FetchDescriptor<InterviewSessionEntity>()
        let sessions = try modelContext.fetch(descriptor)
        for session in sessions {
            modelContext.delete(session)
        }
        try modelContext.save()
        Self.logger.info("Deleted all sessions")
    }
}
