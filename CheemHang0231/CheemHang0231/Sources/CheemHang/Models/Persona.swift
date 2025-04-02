import Foundation
import Firebase
import FirebaseFirestore

struct Persona: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var bio: String?
    var imageURL: String?
    var age: Int?
    var breed: String?
    var interests: [String]?
    var isPremium: Bool = false
    var createdAt: Timestamp = Timestamp()
    
    init(id: String? = nil, name: String, bio: String? = nil, imageURL: String? = nil, 
         age: Int? = nil, breed: String? = nil, interests: [String]? = nil, 
         isPremium: Bool = false, createdAt: Timestamp = Timestamp()) {
        self.id = id
        self.name = name
        self.bio = bio
        self.imageURL = imageURL
        self.age = age
        self.breed = breed
        self.interests = interests
        self.isPremium = isPremium
        self.createdAt = createdAt
    }
} 
