import SwiftUI
import FirebaseAuth
import Kingfisher
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingCreatePersona = false
    @State private var showingEditPersona: Persona? = nil
    @State private var showingCalendarSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.personas.isEmpty && !viewModel.isLoading {
                    EmptyProfileState()
                } else {
                    if viewModel.isLoading {
                        ProgressView("Loading personas...")
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.personas) { persona in
                                PersonaCard(persona: persona)
                                    .onTapGesture {
                                        showingEditPersona = persona
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Add calendar integration button
                Button {
                    showingCalendarSettings = true
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(.hunterGreen)
                        Text("Calendar Integration")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.hunterGreenPale.opacity(0.3))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Sign Out Button
                Button {
                    authViewModel.signOut()
                } label: {
                    Text("Sign Out")
                        .fontWeight(.medium)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .padding(.top, 16)
        }
        .navigationTitle("Profile")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        viewModel.loadPersonas()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button {
                        showingCreatePersona = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    #if DEBUG
                    Menu {
                        Button {
                            createTestPersona()
                        } label: {
                            Label("Test Persona", systemImage: "exclamationmark.triangle")
                        }
                        
                        Button {
                            testAppPathPersonaCreation()
                        } label: {
                            Label("App Path Test", systemImage: "testtube.2")
                        }
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                    }
                    #endif
                }
            }
        }
        .onAppear {
            viewModel.loadPersonas()
        }
        .sheet(isPresented: $showingCreatePersona, onDismiss: {
            viewModel.loadPersonas()
        }) {
            PersonaFormView(viewModel: viewModel, persona: nil, onComplete: {
                print("DEBUG: Create persona onComplete called")
                viewModel.loadPersonas()
            })
        }
        .sheet(item: $showingEditPersona, onDismiss: {
            print("DEBUG: Edit persona sheet dismissed")
            viewModel.loadPersonas()
        }) { persona in
            PersonaFormView(viewModel: viewModel, persona: persona, onComplete: {
                print("DEBUG: Edit persona onComplete called")
                viewModel.loadPersonas()
            })
        }
        .sheet(isPresented: $showingCalendarSettings) {
            GoogleCalendarAuthView()
        }
        .onChange(of: viewModel.personas) { oldValue, newValue in
            print("DEBUG: Personas changed from \(oldValue.count) to \(newValue.count)")
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    // Test function to create a persona directly
    private func createTestPersona() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                print("DEBUG: Creating test persona directly for user \(userId)")
                
                let db = Firestore.firestore()
                let personaRef = db.collection("users").document(userId).collection("personas").document()
                
                let timestamp = Timestamp(date: Date())
                let testPersona: [String: Any] = [
                    "name": "Test Direct \(Int(Date().timeIntervalSince1970))",
                    "description": "Created directly for testing",
                    "userID": userId,
                    "isDefault": false,
                    "createdAt": timestamp,
                    "updatedAt": timestamp
                ]
                
                // Write directly to Firestore
                try await personaRef.setData(testPersona)
                print("DEBUG: Successfully created test persona with ID: \(personaRef.documentID)")
                
                // Force reload personas
                viewModel.loadPersonas()
                
                // Manually verify if persona exists by direct read
                let snapshot = try await db.collection("users").document(userId).collection("personas").getDocuments()
                print("DEBUG: Direct verification found \(snapshot.documents.count) personas")
                for doc in snapshot.documents {
                    print("DEBUG: Found persona: \(doc.documentID) - \(doc.data()["name"] ?? "unnamed")")
                }
            } catch {
                print("DEBUG: Error creating test persona: \(error.localizedDescription)")
            }
        }
    }
    
    // Test function that creates a persona using the app's standard path
    private func testAppPathPersonaCreation() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                print("DEBUG: Testing persona creation through app path for user \(userId)")
                
                // Create a test persona using the app's standard path through FirestoreService
                let testPersona = Persona(
                    id: nil,
                    name: "App Path Test \(Int(Date().timeIntervalSince1970))",
                    description: "Created using app path for testing",
                    avatarURL: nil,
                    userID: userId,
                    isDefault: false
                )
                
                // Use the FirestoreService to create the persona
                let firestoreService = FirestoreService()
                let personaId = try await firestoreService.createPersona(testPersona, for: userId)
                print("DEBUG: Successfully created persona through app path with ID: \(personaId)")
                
                // Verify the path was correct
                let db = Firestore.firestore()
                print("DEBUG: Verifying persona exists at path: users/\(userId)/personas/\(personaId)")
                let docRef = db.collection("users").document(userId).collection("personas").document(personaId)
                let docSnapshot = try await docRef.getDocument()
                
                if docSnapshot.exists {
                    print("DEBUG: ✅ SUCCESS! Persona document exists at correct path")
                    print("DEBUG: Document data: \(docSnapshot.data() ?? [:])")
                } else {
                    print("DEBUG: ❌ ERROR! Persona document does NOT exist at path")
                }
                
                // Force reload personas
                viewModel.loadPersonas()
                
                // Check entire persona collection
                let collectionRef = db.collection("users").document(userId).collection("personas")
                print("DEBUG: Checking entire personas collection at path: users/\(userId)/personas")
                let snapshot = try await collectionRef.getDocuments()
                print("DEBUG: Found \(snapshot.documents.count) total personas in collection")
                
                for doc in snapshot.documents {
                    print("DEBUG: ▶️ Persona: \(doc.documentID) - \(doc.data()["name"] ?? "unnamed")")
                }
            } catch {
                print("DEBUG: ❌ ERROR creating persona through app path: \(error.localizedDescription)")
                print("DEBUG: Full error: \(error)")
            }
        }
    }
}

struct PersonaCardDetailed: View {
    let persona: Persona
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                if let avatarURL = persona.avatarURL, !avatarURL.isEmpty {
                    KFImage(URL(string: avatarURL))
                        .placeholder {
                            Image(systemName: "person.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .foregroundColor(.gray)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .frame(width: 80, height: 80)
                        .background(Color.hunterGreenPale)
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(persona.name)
                            .font(.headline)
                        
                        if persona.isDefault {
                            Text("Default")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.hunterGreen)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    Text(persona.description)
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.hunterGreenDark)
        .cornerRadius(12)
    }
}

struct EmptyProfileState: View {
    @State private var showingCreatePersona = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.7))
            
            Text("No personas found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create personas to represent different facets of yourself when meeting with others.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            
            Button {
                showingCreatePersona = true
            } label: {
                Text("Create Your First Persona")
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: 280)
                    .background(Color.hunterGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 400)
        .sheet(isPresented: $showingCreatePersona) {
            PersonaFormView(viewModel: ProfileViewModel(), persona: nil, onComplete: {})
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
} 