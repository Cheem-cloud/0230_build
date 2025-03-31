import SwiftUI

struct PersonasView: View {
    @StateObject private var viewModel = PersonasViewModel()
    @State private var showingAddPersona = false
    
    var body: some View {
        List {
            ForEach(viewModel.personas) { persona in
                PersonaCard(persona: persona)
                    .padding(.vertical, 4)
            }
            .onDelete(perform: viewModel.deletePersona)
        }
        .navigationTitle("My Personas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingAddPersona = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPersona) {
            AddPersonaView(onComplete: { viewModel.loadPersonas() })
        }
        .onAppear {
            viewModel.loadPersonas()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

struct PersonaCard: View {
    let persona: Persona
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let avatarURL = persona.avatarURL, !avatarURL.isEmpty {
                    AsyncImage(url: URL(string: avatarURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading) {
                    Text(persona.name)
                        .font(.title3)
                        .bold()
                    
                    Text(persona.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            if persona.isDefault {
                Text("Default Persona")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        PersonasView()
    }
} 