import SwiftUI
import FirebaseAuth
import CheemHang

struct HangoutCreationView: View {
    let partnerPersona: Persona
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var selectedHangoutType: HangoutType?
    @State private var selectedDuration: Duration?
    @State private var selectedTimeSlot: TimeSlot?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentStep), total: 3)
                    .padding(.horizontal)
                    .padding(.top)
                
                HStack {
                    Text("Step \(currentStep + 1) of 3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Main content area
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
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    
                    if currentStep < 2 {
                        Button("Next") {
                            currentStep += 1
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
                        .background(isRequestEnabled ? Color.hunterGreen : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(!isRequestEnabled)
                    }
                }
                .padding()
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
        VStack(spacing: 20) {
            Text("What would you like to do with \(partnerPersona.name)?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(HangoutType.allCases) { type in
                        HangoutTypeCard(
                            type: type,
                            isSelected: selectedHangoutType == type,
                            onTap: {
                                selectedHangoutType = type
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Duration selection view
    private var durationView: some View {
        VStack(spacing: 20) {
            Text("How long should the \(selectedHangoutType?.rawValue.lowercased() ?? "hangout") last?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Duration.allCases) { duration in
                        DurationCard(
                            duration: duration,
                            isSelected: selectedDuration == duration,
                            onTap: {
                                selectedDuration = duration
                            }
                        )
                    }
                }
                .padding(.horizontal)
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
    
    private var isNextEnabled: Bool {
        switch currentStep {
        case 0:
            return selectedHangoutType != nil
        case 1:
            return selectedDuration != nil
        default:
            return false
        }
    }
    
    private var isRequestEnabled: Bool {
        return selectedTimeSlot != nil
    }
    
    private func requestHangout() {
        guard let hangoutType = selectedHangoutType,
              let timeSlot = selectedTimeSlot else {
            return
        }
        
        // Create the hangout
        let viewModel = HangoutCreationViewModel()
        Task {
            await viewModel.createHangout(
                with: partnerPersona,
                type: hangoutType,
                timeSlot: timeSlot
            )
            await MainActor.run {
                dismiss()
                onComplete()
            }
        }
    }
}

// Card view for hangout type selection
struct HangoutTypeCard: View {
    let type: HangoutType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: type.iconName)
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .gray)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(.headline)
                
                Text(type.description)
                    .font(.caption)
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

// Card view for duration selection
struct DurationCard: View {
    let duration: Duration
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "clock")
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .gray)
                .frame(width: 50)
            
            Text(duration.displayName)
                .font(.headline)
            
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

// Content view for time selection
struct TimeSelectionContentView: View {
    let partnerPersona: Persona
    let duration: Duration
    let onTimeSelected: (TimeSlot) -> Void
    
    @StateObject private var viewModel = TimeSelectionViewModel()
    @State private var selectedTimeSlot: TimeSlot?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select an available time")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            if viewModel.isLoading {
                ProgressView("Checking availability...")
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
                for: partnerPersona.userID,
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
        description: "A fun-loving version that enjoys adventures",
        avatarURL: nil,
        userID: "user123",
        isDefault: false
    )
    
    return HangoutCreationView(partnerPersona: samplePersona, onComplete: {})
} 