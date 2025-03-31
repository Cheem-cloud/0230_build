import SwiftUI
import Kingfisher

struct HangoutsView: View {
    @StateObject private var viewModel = HangoutsViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading hangouts...")
            } else if viewModel.hangouts.isEmpty {
                EmptyHangoutsView()
            } else {
                List {
                    if !viewModel.upcomingHangouts.isEmpty {
                        Section("Upcoming") {
                            ForEach(viewModel.upcomingHangouts) { hangout in
                                HangoutCard(hangout: hangout, viewModel: viewModel)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    
                    if !viewModel.pastHangouts.isEmpty {
                        Section("Past") {
                            ForEach(viewModel.pastHangouts) { hangout in
                                HangoutCard(hangout: hangout, viewModel: viewModel)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Hangouts")
        .onAppear {
            viewModel.loadHangouts()
        }
        .refreshable {
            viewModel.loadHangouts()
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
}

struct EmptyHangoutsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Hangouts Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Browse your partner's personas and schedule a hangout!")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            NavigationLink {
                PartnerPersonasView()
            } label: {
                Text("Browse Partner Personas")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct HangoutCard: View {
    let hangout: Hangout
    let viewModel: HangoutsViewModel
    @State private var showCancelConfirmation = false
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(hangout.title)
                        .font(.headline)
                    
                    if let location = hangout.location, !location.isEmpty {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.caption)
                            Text(location)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if hangout.status == .accepted && hangout.startDate > Date() {
                    Menu {
                        Button(role: .destructive) {
                            showCancelConfirmation = true
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            
            Divider()
            
            // Time and date
            HStack {
                Image(systemName: "calendar")
                Text(dateFormatter.string(from: hangout.startDate))
                
                if hangout.startDate != hangout.endDate {
                    Text("to")
                    Text(dateFormatter.string(from: hangout.endDate))
                }
            }
            .font(.callout)
            
            // Personas
            VStack(alignment: .leading, spacing: 8) {
                Text("Personas:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    // Display partner persona info
                    if let partner = viewModel.personaDetails[hangout.inviteePersonaID] {
                        PersonaBadge(persona: partner)
                    } else {
                        ProgressView()
                            .frame(height: 30)
                    }
                    
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.secondary)
                    
                    // Display user persona info
                    if let user = viewModel.personaDetails[hangout.creatorPersonaID] {
                        PersonaBadge(persona: user)
                    } else {
                        ProgressView()
                            .frame(height: 30)
                    }
                }
            }
            
            if !hangout.description.isEmpty {
                Text(hangout.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Cancel Hangout", isPresented: $showCancelConfirmation) {
            Button("Keep Hangout", role: .cancel) {}
            Button("Cancel Hangout", role: .destructive) {
                Task {
                    await viewModel.cancelHangout(hangout)
                }
            }
        } message: {
            Text("Are you sure you want to cancel this hangout? This will remove it from both calendars.")
        }
    }
}

struct PersonaBadge: View {
    let persona: Persona
    
    var body: some View {
        HStack {
            if let avatarURL = persona.avatarURL, !avatarURL.isEmpty {
                KFImage(URL(string: avatarURL))
                    .placeholder {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Text(persona.name)
                .font(.callout)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        HangoutsView()
    }
} 