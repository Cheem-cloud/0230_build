import SwiftUI

struct PersonaCard: View {
    let persona: Persona
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                if let imageURL = persona.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        } else if phase.error != nil {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .frame(height: 200)
                        } else {
                            ProgressView()
                                .frame(height: 200)
                        }
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(Color.lightGray)
                }
                
                if persona.isPremium {
                    Image(systemName: "star.fill")
                        .foregroundColor(.mutedGold)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.8)))
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(persona.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.deepRed)
                    
                    Spacer()
                    
                    if let age = persona.age {
                        Text("\(age)")
                            .font(.headline)
                            .foregroundColor(.charcoal.opacity(0.7))
                    }
                }
                
                if let breed = persona.breed {
                    Text(breed)
                        .font(.subheadline)
                        .foregroundColor(.charcoal)
                }
                
                if let bio = persona.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.charcoal.opacity(0.8))
                        .lineLimit(3)
                        .padding(.top, 4)
                }
                
                HStack {
                    ForEach(persona.interests ?? [], id: \.self) { interest in
                        Text(interest)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.tealGreen))
                    }
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        .onTapGesture {
            onTap()
        }
    }
} 