import SwiftUI
import FirebaseAuth

// These types come from: CheemHang0231/Sources/CheemHang/Models/HangoutModels.swift

struct HangoutCreationView: View {
    let partnerPersona: Persona
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var selectedType: HangoutType?
    @State private var otherTypeDescription: String = ""
    @State private var selectedDuration: Duration?
    @State private var selectedTimeSlot: TimeSlot?
    
    // Instead of using CustomHangoutType directly, use computed properties
    private var hangoutTypeDisplayName: String {
        guard let selectedType = selectedType else { return "" }
        if selectedType == .other && !otherTypeDescription.isEmpty {
            return otherTypeDescription
        }
        return selectedType.rawValue
    }
    
    private var hangoutTypeDescription: String {
        guard let selectedType = selectedType else { return "" }
        if selectedType == .other && !otherTypeDescription.isEmpty {
            return otherTypeDescription
        }
        return selectedType.description
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentStep), total: 3)
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                HStack {
                    Text("Step \(currentStep + 1) of 3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 12)
                
                // Main content area - in a ScrollView to ensure it's scrollable on smaller screens
                ScrollView {
                    VStack(spacing: 20) {
                        switch currentStep {
                        case 0:
                            hangoutTypeView
                        case 1:
                            durationView
                        case 2:
                            timeSelectionView
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // Navigation buttons
                VStack(spacing: 12) {
                    if currentStep == 0 && selectedType == .other {
                        TextField("Describe your hangout type...", text: $otherTypeDescription)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    HStack(spacing: 12) {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        
                        if currentStep < 2 {
                            Button("Next") {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isNextEnabled ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(!isNextEnabled)
                        } else {
                            Button("Request Hangout") {
                                requestHangout()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isRequestEnabled ? Color.deepRed : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(!isRequestEnabled)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
            }
            .navigationTitle("Request Hangout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Hangout type selection view
    private var hangoutTypeView: some View {
        VStack(spacing: 24) {
            Text("What would you like to do with \(partnerPersona.name)?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            VStack(spacing: 16) {
                ForEach(HangoutType.allCases) { type in
                    HangoutTypeCard(
                        type: type,
                        isSelected: selectedType == type,
                        onTap: {
                            withAnimation {
                                selectedType = type
                            }
                        }
                    )
                }
            }
        }
    }
    
    // Duration selection view
    private var durationView: some View {
        VStack(spacing: 24) {
            let typeLabel = selectedType == .other && !otherTypeDescription.isEmpty ? 
                            otherTypeDescription.lowercased() : 
                            selectedType?.rawValue.lowercased() ?? "hangout"
            
            Text("How long should the \(typeLabel) last?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            VStack(spacing: 16) {
                ForEach(Duration.allCases) { duration in
                    DurationCard(
                        duration: duration,
                        isSelected: selectedDuration == duration,
                        onTap: {
                            withAnimation {
                                selectedDuration = duration
                            }
                        }
                    )
                }
            }
        }
    }
    
    // Time selection view
    private var timeSelectionView: some View {
        VStack {
            if let selectedDuration = selectedDuration {
                TimeSelectionContentView(
                    partnerPersona: partnerPersona,
                    duration: selectedDuration,
                    onTimeSelected: { timeSlot in
                        selectedTimeSlot = timeSlot
                    }
                )
            } else {
                Text("Please select a duration first")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Check if next button should be enabled
    private var isNextEnabled: Bool {
        switch currentStep {
        case 0:
            return selectedType != nil && (selectedType != .other || !otherTypeDescription.isEmpty)
        case 1:
            return selectedDuration != nil
        default:
            return false
        }
    }
    
    // Check if request button should be enabled
    private var isRequestEnabled: Bool {
        return selectedTimeSlot != nil
    }
    
    // Request hangout
    private func requestHangout() {
        guard let selectedType = selectedType,
              let selectedDuration = selectedDuration,
              let selectedTimeSlot = selectedTimeSlot else {
            return
        }
        
        // In a real app, this would send the request to the backend
        print("Requesting hangout of type: \(hangoutTypeDisplayName)")
        print("Duration: \(selectedDuration.displayName)")
        print("Time: \(selectedTimeSlot.dayString) at \(selectedTimeSlot.timeRangeString)")
        
        // Show success and call the completion handler
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onComplete()
            self.dismiss()
        }
    }
}

// Card view for hangout type selection
struct HangoutTypeCard: View {
    let type: HangoutType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background circle
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: type.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text(type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 22))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(isSelected ? Color.blue.opacity(0.08) : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// Card view for duration selection
struct DurationCard: View {
    let duration: Duration
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background circle
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(duration.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Format time in a user-friendly way
                Text(formatTime(seconds: Int(duration.rawValue)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 22))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(isSelected ? Color.blue.opacity(0.08) : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    // Helper function to format seconds into readable text
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours) hour\(hours > 1 ? "s" : "") and \(minutes) minute\(minutes > 1 ? "s" : "")" : "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(minutes) minute\(minutes > 1 ? "s" : "")"
        }
    }
}

// Time selection content view
struct TimeSelectionContentView: View {
    @StateObject private var viewModel = TimeSelectionViewModel()
    @State private var selectedTimeSlot: TimeSlot?
    let partnerPersona: Persona
    let duration: Duration
    let onTimeSelected: (TimeSlot) -> Void
    
    var body: some View {
        VStack {
            // Header showing what we're scheduling
            Text("Find a time for your \(duration.displayName) hangout")
                .font(.headline)
                .padding(.vertical)
            
            if viewModel.isLoading {
                ProgressView("Checking availability...")
                    .padding()
            } else if viewModel.error != nil {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Calendar Access Required")
                        .font(.headline)
                    
                    Text("Both you and your partner need to connect Google Calendar to schedule hangouts.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    NavigationLink {
                        GoogleCalendarAuthView()
                    } label: {
                        Text("Connect Your Calendar")
                            .padding()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            } else if viewModel.availableTimeSlots.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("No available times found")
                        .font(.headline)
                    
                    Text("Try a different duration or check back later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.availableTimeSlots) { timeSlot in
                            TimeSlotCard(
                                timeSlot: timeSlot,
                                isSelected: selectedTimeSlot?.id == timeSlot.id,
                                onTap: {
                                    selectedTimeSlot = timeSlot
                                    onTimeSelected(timeSlot)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            viewModel.loadAvailableTimes(
                for: partnerPersona.id ?? "unknown",
                duration: duration.rawValue
            )
        }
    }
}

// Card view for time slot selection
struct TimeSlotCard: View {
    let timeSlot: TimeSlot
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeSlot.dayString)
                    .font(.headline)
                
                Text(timeSlot.timeRangeString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    let samplePersona = Persona(
        id: "sample",
        name: "Fun Persona",
        bio: "A fun-loving version that enjoys adventures",
        imageURL: nil,
        age: 28,
        breed: "Golden Retriever",
        interests: ["Hiking", "Beach"],
        isPremium: false
    )
    
    HangoutCreationView(partnerPersona: samplePersona, onComplete: {})
} 