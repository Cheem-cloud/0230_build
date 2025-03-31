import Foundation
import FirebaseFirestore

struct Persona: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var avatarURL: String?
    var userID: String
    var isDefault: Bool
    var createdAt: Date?
    var updatedAt: Date?
    
    // Add hash and equality methods
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Persona, rhs: Persona) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Initialization
    
    init(id: String? = nil, name: String, description: String, avatarURL: String? = nil, 
         userID: String, isDefault: Bool = false, createdAt: Date? = Date(), updatedAt: Date? = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.avatarURL = avatarURL
        self.userID = userID
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Codable Implementation
    
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
    
    init(from decoder: Decoder) throws {
        print("DEBUG: Starting to decode Persona")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Initialize required properties with default values first
        id = nil
        name = ""
        description = ""
        avatarURL = nil
        userID = ""
        isDefault = false
        createdAt = nil
        updatedAt = nil
        
        // Try decoding each field with error reporting
        do {
            id = try container.decodeIfPresent(String.self, forKey: .id)
            print("DEBUG: Decoded id: \(id ?? "nil")")
        } catch {
            print("DEBUG: Error decoding id: \(error.localizedDescription)")
        }
        
        do {
            name = try container.decode(String.self, forKey: .name)
            print("DEBUG: Decoded name: \(name)")
        } catch {
            print("DEBUG: Error decoding name: \(error.localizedDescription)")
            throw error
        }
        
        do {
            description = try container.decode(String.self, forKey: .description)
            print("DEBUG: Decoded description: \(description)")
        } catch {
            print("DEBUG: Error decoding description: \(error.localizedDescription)")
            throw error
        }
        
        do {
            avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
            print("DEBUG: Decoded avatarURL: \(avatarURL ?? "nil")")
        } catch {
            print("DEBUG: Error decoding avatarURL: \(error.localizedDescription)")
            avatarURL = nil
        }
        
        do {
            userID = try container.decode(String.self, forKey: .userID)
            print("DEBUG: Decoded userID: \(userID)")
        } catch {
            print("DEBUG: Error decoding userID: \(error.localizedDescription)")
            throw error
        }
        
        do {
            isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
            print("DEBUG: Decoded isDefault: \(isDefault)")
        } catch {
            print("DEBUG: Error decoding isDefault: \(error.localizedDescription), defaulting to false")
            isDefault = false
        }
        
        do {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
            print("DEBUG: Decoded createdAt: \(createdAt?.description ?? "nil")")
        } catch {
            print("DEBUG: Error decoding createdAt: \(error.localizedDescription)")
            createdAt = Date()
        }
        
        do {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
            print("DEBUG: Decoded updatedAt: \(updatedAt?.description ?? "nil")")
        } catch {
            print("DEBUG: Error decoding updatedAt: \(error.localizedDescription)")
            updatedAt = Date()
        }
        
        print("DEBUG: Successfully decoded entire Persona")
    }
} 
