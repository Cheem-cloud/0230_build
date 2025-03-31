import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class PersonasViewModel: ObservableObject {
    @Published var personas: [Persona] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firestoreService = FirestoreService()
    
    func loadPersonas() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        Task {
            do {
                let fetchedPersonas = try await firestoreService.getPersonas(for: userId)
                
                DispatchQueue.main.async {
                    self.personas = fetchedPersonas
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
    
    func createPersona(name: String, description: String, avatarURL: String?, makeDefault: Bool) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "com.cheemhang.personaviewmodel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // If this is the first persona or set as default, update any existing default
        if makeDefault {
            await updateDefaultPersonaStatus(makeDefault: makeDefault)
        }
        
        let newPersona = Persona(
            name: name,
            description: description,
            avatarURL: avatarURL,
            userID: userId,
            isDefault: makeDefault || personas.isEmpty // First persona is default
        )
        
        let personaId = try await firestoreService.createPersona(newPersona, for: userId)
        // This value could be used, but we'll just acknowledge it was returned
    }
    
    private func updateDefaultPersonaStatus(makeDefault: Bool) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if makeDefault, !personas.isEmpty {
            // Find current default persona
            if let defaultPersona = personas.first(where: { $0.isDefault }),
               let _ = defaultPersona.id {
                // Update to non-default
                var updatedPersona = defaultPersona
                updatedPersona.isDefault = false
                try? await firestoreService.updatePersona(updatedPersona, for: userId)
            }
        }
    }
    
    func deletePersona(at offsets: IndexSet) {
        for index in offsets {
            guard let personaId = personas[index].id,
                  let userId = Auth.auth().currentUser?.uid else { continue }
            
            Task {
                do {
                    try await firestoreService.deletePersona(personaId)
                    
                    // If we deleted the default persona and others exist, make another one default
                    if personas[index].isDefault, personas.count > 1 {
                        if let _ = personas.first(where: { $0.id != personaId }),
                           var updatedPersona = personas.first(where: { $0.id != personaId }) {
                            updatedPersona.isDefault = true
                            try await firestoreService.updatePersona(updatedPersona, for: userId)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.loadPersonas()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.error = error
                    }
                }
            }
        }
    }
    
    func setAsDefault(persona: Persona) {
        guard let personaId = persona.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            // First, remove default status from current default
            if let defaultPersona = personas.first(where: { $0.isDefault && $0.id != personaId }),
               let _ = defaultPersona.id {
                var updatedDefault = defaultPersona
                updatedDefault.isDefault = false
                try? await firestoreService.updatePersona(updatedDefault, for: userId)
            }
            
            // Set new default
            var updatedPersona = persona
            updatedPersona.isDefault = true
            try? await firestoreService.updatePersona(updatedPersona, for: userId)
            
            DispatchQueue.main.async {
                self.loadPersonas()
            }
        }
    }
} 