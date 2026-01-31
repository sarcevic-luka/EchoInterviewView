import Foundation

struct Question: Codable, Equatable, Identifiable {
    let id: UUID
    let text: String
    
    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}
