import Foundation
import FirebaseFirestoreSwift

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var photoURL: String?
    var calendarID: String?
    var calendarAccessToken: String?
    var calendarRefreshToken: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case photoURL
        case calendarID
        case calendarAccessToken
        case calendarRefreshToken
        case createdAt
        case updatedAt
    }
    
    static func create(from authUser: FirebaseAuth.User) -> AppUser {
        return AppUser(
            id: authUser.uid,
            email: authUser.email ?? "",
            displayName: authUser.displayName ?? "",
            photoURL: authUser.photoURL?.absoluteString
        )
    }
} 