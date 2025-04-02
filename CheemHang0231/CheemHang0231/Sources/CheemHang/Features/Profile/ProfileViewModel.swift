import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation
import FirebaseMessaging

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var personas: [Persona] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var bio: String = ""
    
    private let firestoreService = FirestoreService()
    
    // Add a new method to ensure user document exists
    func ensureUserDocumentExists() async -> Bool {
        guard let user = Auth.auth().currentUser else {
            print("DEBUG: Cannot create user document - No user logged in")
            return false
        }
        
        print("DEBUG: Ensuring user document exists for \(user.uid)")
        
        do {
            // Check if user document exists
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(user.uid)
            let doc = try await docRef.getDocument()
            
            if !doc.exists {
                print("DEBUG: User document doesn't exist - creating it now")
                
                // Create basic user document
                let userData: [String: Any] = [
                    "displayName": user.displayName ?? "User",
                    "email": user.email ?? "",
                    "photoURL": user.photoURL?.absoluteString ?? "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                try await docRef.setData(userData)
                print("DEBUG: Created user document for \(user.uid)")
                
                // Create initial persona subcollection
                if try await firestoreService.getPersonas(for: user.uid).isEmpty {
                    print("DEBUG: No personas exist - creating default persona")
                    
                    let defaultPersona = Persona(
                        id: nil,
                        name: "Default Persona",
                        description: "My primary persona",
                        avatarURL: nil,
                        userID: user.uid,
                        isDefault: true
                    )
                    
                    let personaId = try await firestoreService.createPersona(defaultPersona, for: user.uid)
                    print("DEBUG: Created default persona with ID: \(personaId)")
                }
                
                return true
            } else {
                print("DEBUG: User document already exists")
                return true
            }
        } catch {
            print("DEBUG: Error checking/creating user document: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            return false
        }
    }
    
    func loadPersonas() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("DEBUG: Cannot load personas - No user logged in")
            return 
        }
        
        print("DEBUG: ProfileViewModel - Starting loadPersonas() for user \(userId)")
        isLoading = true
        personas = [] // Clear current personas while loading
        
        // Force UI update immediately to show loading state
        Task { @MainActor in
            do {
                // First ensure the user document exists
                let _ = await ensureUserDocumentExists()
                
                print("DEBUG: ProfileViewModel - Calling firestoreService.getPersonas()")
                let fetchedPersonas = try await firestoreService.getPersonas(for: userId)
                
                print("DEBUG: ProfileViewModel - Got \(fetchedPersonas.count) personas from Firestore")
                self.personas = fetchedPersonas
                self.isLoading = false
                print("DEBUG: ProfileViewModel - UI updated with \(self.personas.count) personas")
                
                // Debug dump the actual personas
                for persona in fetchedPersonas {
                    print("DEBUG: Loaded persona: \(persona.name) (ID: \(persona.id ?? "nil"), Default: \(persona.isDefault))")
                }
            } catch {
                print("DEBUG: ProfileViewModel - Error loading personas: \(error.localizedDescription)")
                self.error = error
                self.isLoading = false
                print("DEBUG: ProfileViewModel - Updated error state")
            }
        }
    }
    
    func deletePersona(_ personaId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Check if it's the default persona and if there are others
            if let persona = personas.first(where: { $0.id == personaId }),
               persona.isDefault && personas.count > 1 {
                
                // Find another persona to make default
                if let newDefault = personas.first(where: { $0.id != personaId }) {
                    var updatedPersona = newDefault
                    updatedPersona.isDefault = true
                    try await firestoreService.updatePersona(updatedPersona, for: userId)
                }
            }
            
            try await firestoreService.deletePersona(personaId)
            
            DispatchQueue.main.async {
                self.loadPersonas()
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func setAsDefault(_ persona: Persona) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("DEBUG: Setting persona as default: \(persona.name)")
        
        do {
            // If this is a new persona without an ID, create it first
            var updatedPersona = persona
            if persona.id == nil {
                print("DEBUG: This is a new persona, creating it first")
                let newId = try await firestoreService.createPersona(persona, for: userId)
                updatedPersona.id = newId
                print("DEBUG: Created new persona with ID: \(newId)")
            }
            
            // First, update the current default
            let currentDefault = personas.first(where: { $0.isDefault && $0.id != updatedPersona.id })
            if let current = currentDefault, let _ = current.id {
                print("DEBUG: Unsetting current default: \(current.name)")
                var updatedCurrent = current
                updatedCurrent.isDefault = false
                try await firestoreService.updatePersona(updatedCurrent, for: userId)
            }
            
            // Set the new default
            updatedPersona.isDefault = true
            print("DEBUG: Updating persona to be default: \(updatedPersona.name)")
            if let _ = updatedPersona.id {
                try await firestoreService.updatePersona(updatedPersona, for: userId)
                print("DEBUG: Successfully updated persona as default")
            }
            
            // Refresh the personas list
            await MainActor.run {
                print("DEBUG: Refreshing personas list after setting default")
                self.loadPersonas()
            }
        } catch {
            print("DEBUG: Error setting default persona: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    func updateProfile(name: String, email: String, bio: String) async {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        
        do {
            // Update Firebase Auth profile
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Update Firestore user document
            var userData: [String: Any] = [
                "displayName": name,
                "bio": bio,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            if email != user.email {
                // Use the new recommended method instead of updateEmail
                try await user.sendEmailVerification(beforeUpdatingEmail: email)
                userData["email"] = email
            }
            
            // Get current FCM token and add to update if available
            if let fcmToken = Messaging.messaging().fcmToken {
                userData["fcmToken"] = fcmToken
                print("DEBUG: Including FCM token in profile update: \(fcmToken)")
            }
            
            let db = Firestore.firestore()
            try await db.collection("users").document(user.uid).updateData(userData)
            
            DispatchQueue.main.async {
                self.displayName = name
                self.email = email
                self.bio = bio
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
                self.isLoading = false
            }
        }
    }
} 