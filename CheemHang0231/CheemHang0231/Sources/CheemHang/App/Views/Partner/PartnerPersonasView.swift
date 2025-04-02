import SwiftUI

struct PartnerPersonasView: View {
    @StateObject private var viewModel = PersonasViewModel()
    @State private var selectedPersona: Persona?
    @State private var showDetails = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if viewModel.personas.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 70))
                                .foregroundColor(.deepRed.opacity(0.8))
                                .padding(.bottom, 10)
                            
                            Text("No potential dates found")
                                .font(.headline)
                                .foregroundColor(.charcoal)
                            
                            Text("Create your own persona to start matching")
                                .font(.subheadline)
                                .foregroundColor(.charcoal.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                // Navigate to profile creation
                            }) {
                                Text("Create Your Profile")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.mutedGold)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.personas) { persona in
                                    PersonaCard(persona: persona, onTap: {
                                        selectedPersona = persona
                                        showDetails = true
                                    })
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .refreshable {
                            await viewModel.fetchPersonas()
                        }
                    }
                }
                .navigationTitle("Find a Date")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Refresh action
                            Task {
                                await viewModel.fetchPersonas()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(.mutedGold)
                        }
                    }
                }
                .sheet(isPresented: $showDetails, onDismiss: {
                    selectedPersona = nil
                }) {
                    if let persona = selectedPersona {
                        PersonaDetailView(persona: persona)
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .deepRed))
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchPersonas()
                }
            }
        }
    }
} 