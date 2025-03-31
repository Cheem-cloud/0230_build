import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore
import CheemHang

struct PartnerPersonasView: View {
    @StateObject private var viewModel = PartnerPersonasViewModel()
    @State private var selectedPersona: Persona?
    @State private var showingHangoutTypeSelection = false
    @State private var currentIndex = 0
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading partner personas...")
            } else if viewModel.personas.isEmpty {
                EmptyPartnerState()
            } else {
                // Header with page indicator
                HStack {
                    Text("Partner's Personas")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) of \(viewModel.personas.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Carousel
                TabView(selection: $currentIndex) {
                    ForEach(Array(viewModel.personas.enumerated()), id: \.element.id) { index, persona in
                        PartnerPersonaCardView(persona: persona) {
                            // Action when Request Hangout is tapped
                            selectedPersona = persona
                            showingHangoutTypeSelection = true
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 500)
                
                // Navigation controls
                HStack(spacing: 50) {
                    Button {
                        withAnimation {
                            currentIndex = max(0, currentIndex - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(currentIndex > 0 ? .hunterGreenLight : .gray)
                    }
                    .disabled(currentIndex <= 0)
                    
                    Button {
                        withAnimation {
                            currentIndex = min(viewModel.personas.count - 1, currentIndex + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(currentIndex < viewModel.personas.count - 1 ? .hunterGreenLight : .gray)
                    }
                    .disabled(currentIndex >= viewModel.personas.count - 1)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Partner's Personas")
        .onAppear {
            viewModel.loadPartnerPersonas()
        }
        .sheet(isPresented: $showingHangoutTypeSelection) {
            if let persona = selectedPersona {
                HangoutTypeSelectionView(partnerPersona: persona)
            }
        }
        .refreshable {
            viewModel.loadPartnerPersonas()
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

// New Partner Persona Card View (no swiping, simpler design)
struct PartnerPersonaCardView: View {
    let persona: Persona
    let onRequestHangout: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Avatar/Image
        ZStack(alignment: .bottom) {
                if let avatarURL = persona.avatarURL, !avatarURL.isEmpty {
                    KFImage(URL(string: avatarURL))
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                )
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(height: 350)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.hunterGreenDark)
                        .frame(height: 350)
                        .overlay(
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(60)
                                .foregroundColor(.white)
                        )
                }
                
                // Name overlay on the image
                VStack(alignment: .leading) {
                Text(persona.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .background(LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            
            // Description and button
            VStack(spacing: 16) {
                Text(persona.description)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                Button(action: onRequestHangout) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Request Hangout")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.hunterGreen)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .background(Color.white)
        }
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

// New view for Hangout Type Selection (Step 3 in the flow)
struct HangoutTypeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let partnerPersona: Persona
    @State private var selectedType: HangoutType?
    @State private var showingDurationSelection = false
    
    // Example hangout types (these would come from settings)
    let hangoutTypes: [HangoutType] = [
        HangoutType(id: "coffee", name: "Coffee", icon: "cup.and.saucer.fill"),
        HangoutType(id: "lunch", name: "Lunch", icon: "fork.knife"),
        HangoutType(id: "dinner", name: "Dinner", icon: "wineglass"),
        HangoutType(id: "movie", name: "Movie", icon: "film"),
        HangoutType(id: "walk", name: "Walk", icon: "figure.walk"),
        HangoutType(id: "videocall", name: "Video Call", icon: "video.fill"),
        HangoutType(id: "other", name: "Other", icon: "ellipsis.circle.fill")
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header with partner persona info
                HStack {
                    if let avatarURL = partnerPersona.avatarURL, !avatarURL.isEmpty {
                        KFImage(URL(string: avatarURL))
                            .placeholder {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .foregroundColor(.gray)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .frame(width: 60, height: 60)
                            .background(Color.hunterGreenDark)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Hangout with")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(partnerPersona.name)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.hunterGreenPale.opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Text("Select Hangout Type")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Grid of hangout types
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(hangoutTypes, id: \.id) { type in
                        Button {
                            selectedType = type
                            showingDurationSelection = true
                        } label: {
                            VStack {
                                Image(systemName: type.icon)
                                    .font(.system(size: 30))
                                    .padding()
                                    .background(Color.hunterGreenLight)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                
                                Text(type.name)
                                    .font(.headline)
                                    .foregroundColor(Color.hunterGreen)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.hunterGreenPale.opacity(0.2))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Request Hangout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showingDurationSelection) {
                if let type = selectedType {
                    DurationSelectionView(partnerPersona: partnerPersona, hangoutType: type)
                }
            }
        }
    }
}

// New view for Duration Selection (Step 4 in the flow)
struct DurationSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let partnerPersona: Persona
    let hangoutType: HangoutType
    @State private var selectedDuration: Duration?
    @State private var showingTimeSelection = false
    
    // Available durations
    let durations: [Duration] = [
        Duration(minutes: 30, name: "30 minutes"),
        Duration(minutes: 60, name: "1 hour"),
        Duration(minutes: 90, name: "1.5 hours"),
        Duration(minutes: 120, name: "2 hours")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header showing the selected persona and hangout type
            VStack(spacing: 10) {
                Text("Hangout with \(partnerPersona.name)")
                    .font(.headline)
                
                HStack {
                    Image(systemName: hangoutType.icon)
                    Text(hangoutType.name)
                }
                .foregroundColor(Color.hunterGreen)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.hunterGreenPale.opacity(0.3))
            .cornerRadius(10)
            
            Text("Select Duration")
                .font(.title2)
                        .fontWeight(.bold)
                .padding(.top)
            
            // Duration options
            ForEach(durations) { duration in
                Button {
                    selectedDuration = duration
                    showingTimeSelection = true
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color.hunterGreen)
                        
                        Text(duration.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.hunterGreenPale.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
                        .padding()
        .navigationTitle("Select Duration")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingTimeSelection) {
            if let duration = selectedDuration {
                TimeSelectionView(
                    partnerPersona: partnerPersona,
                    hangoutType: hangoutType,
                    duration: duration
                )
            }
        }
    }
}

// New view for Time Selection (Step 5 in the flow)
struct TimeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TimeSelectionViewModel()
    
    let partnerPersona: Persona
    let hangoutType: HangoutType
    let duration: Duration
    
    @State private var selectedTimeSlot: TimeSlot?
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack {
            // Header with hangout details
            VStack(spacing: 5) {
                Text("Hangout with \(partnerPersona.name)")
                    .font(.headline)
                
                HStack {
                    Image(systemName: hangoutType.icon)
                    Text(hangoutType.name)
                }
                .foregroundColor(Color.hunterGreen)
                
                Text("\(duration.name)")
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.hunterGreenPale.opacity(0.3))
            .cornerRadius(10)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Checking calendar availability...")
                Spacer()
            } else if viewModel.availableTimeSlots.isEmpty {
                Spacer()
                Text("No available time slots found")
                    .font(.headline)
                
                Text("Try a different duration or check back later")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                Text("Select Available Time")
                    .font(.title2)
                        .fontWeight(.bold)
                    .padding(.top)
                
                List {
                    ForEach(viewModel.availableTimeSlots) { timeSlot in
                        Button {
                            selectedTimeSlot = timeSlot
                            showingConfirmation = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(timeSlot.formattedDate)
                                        .font(.headline)
                                    
                                    Text("\(timeSlot.formattedStartTime) - \(timeSlot.formattedEndTime)")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Spacer()
        }
                        .padding()
        .navigationTitle("Select Time")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load available times based on partner's calendar
            viewModel.loadAvailableTimes(
                for: partnerPersona.userID,
                duration: duration.timeInterval
            )
        }
        .alert("Confirm Hangout", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            
            Button("Confirm") {
                if let timeSlot = selectedTimeSlot {
                    viewModel.createHangout(
                        with: partnerPersona,
                        type: hangoutType,
                        timeSlot: timeSlot
                    )
                    dismiss()
                }
            }
        } message: {
            if let timeSlot = selectedTimeSlot {
                Text("Request a \(hangoutType.name) with \(partnerPersona.name) on \(timeSlot.formattedDate) at \(timeSlot.formattedStartTime)?")
            } else {
                Text("Confirm this hangout request?")
            }
        }
    }
}

// Time selection view model
class TimeSelectionViewModel: ObservableObject {
    @Published var availableTimeSlots: [TimeSlot] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firestoreService = FirestoreService()
    private let calendarService = CalendarService.shared
    
    func loadAvailableTimes(for partnerId: String, duration: TimeInterval) {
        isLoading = true
        
        Task {
            do {
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "com.cheemhang.calendar", code: 401, 
                           userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                print("Finding mutual availability for users \(currentUserId) and \(partnerId)")
                
                // Start date is today, end date is 14 days from now
                let startDate = Calendar.current.startOfDay(for: Date())
                let endDate = Calendar.current.date(byAdding: .day, value: 14, to: startDate)!
                
                // Get mutual availability for both users
                let availableIntervals = try await calendarService.findMutualAvailability(
                    userIDs: [currentUserId, partnerId],
                    startDate: startDate,
                    endDate: endDate,
                    duration: duration
                )
                
                print("Found \(availableIntervals.count) available time slots")
                
                // Convert DateIntervals to TimeSlots
                let slots = availableIntervals.map { interval in
                    TimeSlot(start: interval.start, end: interval.end)
                }
                
                // Sort by start time
                let sortedSlots = slots.sorted(by: { $0.start < $1.start })
                
                await MainActor.run {
                    self.availableTimeSlots = sortedSlots
                    self.isLoading = false
                }
            } catch {
                print("Error finding mutual availability: \(error.localizedDescription)")
                
                // Fallback to sample data if calendar access fails
                print("Falling back to sample data due to error")
                let sampleSlots = generateSampleTimeSlots(duration: duration)
                
                await MainActor.run {
                    self.availableTimeSlots = sampleSlots
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func createHangout(with partnerPersona: Persona, type: HangoutType, timeSlot: TimeSlot) {
        // This would create the actual hangout in your system
        Task {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            do {
                // Get the user's default persona for the hangout
                let userPersonas = try await firestoreService.getPersonas(for: userId)
                if let defaultPersona = userPersonas.first(where: { $0.isDefault }), let personaId = defaultPersona.id {
                    // Create hangout
                    let hangout = Hangout(
                        title: "\(type.rawValue) with \(partnerPersona.name)",
                        description: "Hangout request",
                        startDate: timeSlot.start,
                        endDate: timeSlot.end,
                        location: nil,
                        creatorID: userId,
                        creatorPersonaID: personaId,
                        inviteeID: partnerPersona.userID,
                        inviteePersonaID: partnerPersona.id ?? "",
                        status: .pending
                    )
                    
                    let hangoutId = try await firestoreService.createHangout(hangout)
                    print("Hangout created successfully with ID: \(hangoutId)")
                    
                    // Add to both users' calendars
                    try await calendarService.createCalendarEvent(
                        for: hangout,
                        userIDs: [userId, partnerPersona.userID]
                    )
                    
                    print("Calendar events created for both users")
                }
            } catch {
                print("Error creating hangout: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    // Generate sample time slots for fallback purposes
    private func generateSampleTimeSlots(duration: TimeInterval) -> [TimeSlot] {
        var slots: [TimeSlot] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Generate slots for the next 7 days
        for day in 1...7 {
            if let date = calendar.date(byAdding: .day, value: day, to: now) {
                // Morning slot
                if let morningStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) {
                    let morningEnd = morningStart.addingTimeInterval(duration)
                    slots.append(TimeSlot(start: morningStart, end: morningEnd))
                }
                
                // Afternoon slot
                if let afternoonStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date) {
                    let afternoonEnd = afternoonStart.addingTimeInterval(duration)
                    slots.append(TimeSlot(start: afternoonStart, end: afternoonEnd))
                }
                
                // Evening slot
                if let eveningStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: date) {
                    let eveningEnd = eveningStart.addingTimeInterval(duration)
                    slots.append(TimeSlot(start: eveningStart, end: eveningEnd))
                }
            }
        }
        
        return slots
    }
}

// Add these extensions for backwards compatibility
extension TimeSlot {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: start)
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: start)
    }
    
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: end)
    }
}

// Add this extension for backwards compatibility
extension HangoutType {
    var icon: String {
        return self.iconName
    }
    
    var name: String {
        return self.rawValue
    }
}

struct EmptyPartnerState: View {
    @StateObject private var viewModel = PartnerPersonasViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Partner Personas Found")
                .font(.title2)
                .bold()
            
            VStack(spacing: 12) {
                Text("This could be due to one of these reasons:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    Label("Your partner hasn't created an account yet", systemImage: "1.circle")
                        .font(.subheadline)
                    
                    Label("Your partner hasn't created any personas", systemImage: "2.circle")
                        .font(.subheadline)
                    
                    Label("Firestore permission issues", systemImage: "3.circle")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.hunterGreenDark)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                Text("Troubleshooting steps:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    Label("Make sure your partner has signed up", systemImage: "checkmark.circle")
                        .font(.subheadline)
                    
                    Label("Make sure both of you have updated your Firestore rules", systemImage: "checkmark.circle")
                        .font(.subheadline)
                    
                    Label("Make sure your partner has created personas in their profile", systemImage: "checkmark.circle")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.hunterGreenDark)
                .cornerRadius(8)
            }
                .padding(.horizontal)
            
            Button {
                viewModel.loadPartnerPersonas()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .padding()
                .background(Color.hunterGreen)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 12)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        PartnerPersonasView()
    }
} 