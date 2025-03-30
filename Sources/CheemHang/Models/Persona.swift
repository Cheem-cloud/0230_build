import Foundation
import FirebaseFirestoreSwift

struct Persona: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var avatarURL: String?
    var userID: String
    var isDefault: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case avatarURL
        case userID
        case isDefault
        case createdAt
        case updatedAt
    }
} 