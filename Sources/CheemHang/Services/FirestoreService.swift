import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

enum FirestoreError: Error {
    case documentNotFound
    case failedToEncode
    case failedToDecode
    case failedToSave
    case failedToDelete
    case failedToFetch
    case unknown
}

class FirestoreService {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    
    // Collections
    private let usersCollection = "users"
    private let personasCollection = "personas"
    private let hangoutsCollection = "hangouts"
    
    // MARK: - User Operations
    
    func getUser(withID id: String) async throws -> AppUser {
        do {
            let document = try await db.collection(usersCollection).document(id).getDocument()
            
            if document.exists, let user = try? document.data(as: AppUser.self) {
                return user
            } else {
                throw FirestoreError.documentNotFound
            }
        } catch {
            throw FirestoreError.failedToFetch
        }
    }
    
    func saveUser(_ user: AppUser) async throws {
        guard let id = user.id else {
            throw FirestoreError.failedToSave
        }
        
        do {
            try await db.collection(usersCollection).document(id).setData(from: user, merge: true)
        } catch {
            throw FirestoreError.failedToSave
        }
    }
    
    // MARK: - Persona Operations
    
    func getPersonas(forUserID userID: String) async throws -> [Persona] {
        do {
            let snapshot = try await db.collection(personasCollection)
                .whereField("userID", isEqualTo: userID)
                .getDocuments()
            
            return snapshot.documents.compactMap { try? $0.data(as: Persona.self) }
        } catch {
            throw FirestoreError.failedToFetch
        }
    }
    
    func savePersona(_ persona: Persona) async throws -> String {
        do {
            if let id = persona.id {
                // Update existing persona
                try await db.collection(personasCollection).document(id).setData(from: persona, merge: true)
                return id
            } else {
                // Create new persona
                let newDocRef = db.collection(personasCollection).document()
                var newPersona = persona
                newPersona.id = newDocRef.documentID
                try await newDocRef.setData(from: newPersona)
                return newDocRef.documentID
            }
        } catch {
            throw FirestoreError.failedToSave
        }
    }
    
    func deletePersona(withID id: String) async throws {
        do {
            try await db.collection(personasCollection).document(id).delete()
        } catch {
            throw FirestoreError.failedToDelete
        }
    }
    
    // MARK: - Hangout Operations
    
    func getHangouts(forUserID userID: String) async throws -> [Hangout] {
        do {
            let creatorSnapshot = try await db.collection(hangoutsCollection)
                .whereField("creatorID", isEqualTo: userID)
                .getDocuments()
            
            let inviteeSnapshot = try await db.collection(hangoutsCollection)
                .whereField("inviteeID", isEqualTo: userID)
                .getDocuments()
            
            var hangouts = creatorSnapshot.documents.compactMap { try? $0.data(as: Hangout.self) }
            hangouts += inviteeSnapshot.documents.compactMap { try? $0.data(as: Hangout.self) }
            
            // Remove duplicates (in case user is both creator and invitee somehow)
            return Array(Set(hangouts))
        } catch {
            throw FirestoreError.failedToFetch
        }
    }
    
    func saveHangout(_ hangout: Hangout) async throws -> String {
        do {
            if let id = hangout.id {
                // Update existing hangout
                try await db.collection(hangoutsCollection).document(id).setData(from: hangout, merge: true)
                return id
            } else {
                // Create new hangout
                let newDocRef = db.collection(hangoutsCollection).document()
                var newHangout = hangout
                newHangout.id = newDocRef.documentID
                try await newDocRef.setData(from: newHangout)
                return newDocRef.documentID
            }
        } catch {
            throw FirestoreError.failedToSave
        }
    }
    
    func updateHangoutStatus(hangoutID: String, status: HangoutStatus) async throws {
        do {
            try await db.collection(hangoutsCollection).document(hangoutID).updateData([
                "status": status.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            throw FirestoreError.failedToSave
        }
    }
} 