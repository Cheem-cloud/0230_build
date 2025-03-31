import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class PartnerPersonasViewModel: ObservableObject {
    @Published var personas: [Persona] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firestoreService = FirestoreService()
    
    // Add a function to ensure user document exists
    private func ensureUserDocumentExists(_ userId: String) async -> Bool {
        print("DEBUG: Ensuring user document exists for \(userId)")
        
        do {
            // Check if user document exists
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(userId)
            let doc = try await docRef.getDocument()
            
            if !doc.exists {
                print("DEBUG: User document doesn't exist - creating it now")
                
                // Create basic user document using current Auth user data
                guard let user = Auth.auth().currentUser else {
                    print("DEBUG: No Auth user found")
                    return false
                }
                
                let userData: [String: Any] = [
                    "displayName": user.displayName ?? "User",
                    "email": user.email ?? "",
                    "photoURL": user.photoURL?.absoluteString ?? "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                try await docRef.setData(userData)
                print("DEBUG: Created user document for \(userId)")
                return true
            } else {
                print("DEBUG: User document already exists for \(userId)")
                return true
            }
        } catch {
            print("DEBUG: Error checking/creating user document: \(error.localizedDescription)")
            return false
        }
    }
    
    func loadPartnerPersonas() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        print("DEBUG: Loading partner personas for current user: \(currentUserId)")
        
        Task {
            do {
                // First ensure the current user document exists
                let _ = await ensureUserDocumentExists(currentUserId)
                
                // Get the partner's ID (since this is a two-person app)
                let partnerId = try await getPartnerId(currentUserId: currentUserId)
                print("DEBUG: Found partner with ID: \(partnerId)")
                
                // Ensure partner document exists too
                let _ = await ensureUserDocumentExists(partnerId)
                
                // Get partner's personas
                let partnerPersonas = try await firestoreService.getPersonas(for: partnerId)
                print("DEBUG: Found \(partnerPersonas.count) personas for partner")
                
                // Log the personas for debugging
                for persona in partnerPersonas {
                    print("DEBUG: Partner persona: \(persona.name), ID: \(persona.id ?? "nil")")
                }
                
                DispatchQueue.main.async {
                    self.personas = partnerPersonas
                    self.isLoading = false
                }
            } catch {
                print("DEBUG: Error loading partner personas: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    // Gets the partner's user ID
    private func getPartnerId(currentUserId: String) async throws -> String {
        // Since this is a two-person app, we just need to find the other user
        // who is not the current user
        let db = Firestore.firestore()
        
        print("DEBUG: Looking for partner user, current user ID: \(currentUserId)")
        
        // First check if we have permission to list users
        do {
            let usersSnapshot = try await db.collection("users").limit(to: 10).getDocuments()
            
            print("DEBUG: Found \(usersSnapshot.documents.count) total users in database")
            
            if usersSnapshot.documents.isEmpty {
                print("DEBUG: No users found in database - you might be the only user so far")
                throw NSError(
                    domain: "com.cheemhang.partnervm",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "No users found in the database. You might be the first user. Wait for your partner to create an account."]
                )
            }
            
            // Filter to find other users (not current user)
            let otherUsers = usersSnapshot.documents.compactMap { document -> String? in
                let userId = document.documentID
                print("DEBUG: Found user: \(userId) - is current user? \(userId == currentUserId)")
                if userId != currentUserId {
                    return userId
                }
                return nil
            }
            
            print("DEBUG: Found \(otherUsers.count) other users besides the current user")
            
            if let partnerId = otherUsers.first {
                print("DEBUG: Partner found with ID: \(partnerId)")
                return partnerId
            } else {
                // If no partner is found, this means the partner hasn't signed up yet
                print("DEBUG: No partner found besides current user")
                throw NSError(
                    domain: "com.cheemhang.partnervm",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Partner account not found. Make sure your partner has created an account with a different email address."]
                )
            }
        } catch {
            print("DEBUG: Error fetching users: \(error.localizedDescription)")
            throw NSError(
                domain: "com.cheemhang.partnervm",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Unable to find partner account. This may be due to Firebase permissions. Please ensure your Firestore rules allow listing users."]
            )
        }
    }
    
    func likePersona(_ persona: Persona) {
        // This is a UI gesture only for now, no backend changes
        // Could be used to track favorite personas in the future
        print("Liked persona: \(persona.name)")
    }
    
    func skipPersona(_ persona: Persona) {
        // This is a UI gesture only for now, no backend changes
        print("Skipped persona: \(persona.name)")
    }
} 