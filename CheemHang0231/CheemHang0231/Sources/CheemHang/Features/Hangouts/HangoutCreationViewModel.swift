import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CheemHang

// Make the class sendable to fix issues with closures
@MainActor
class HangoutCreationViewModel: ObservableObject {
    @Published var personas: [Persona] = []
    @Published var availableTimeSlots: [TimeSlot] = []
    @Published var isLoading = false
    @Published var isLoadingTimes = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private let calendarService = CalendarService.shared
    
    func loadPersonas() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        do {
            let snapshot = try await db.collection("users").document(userId).collection("personas").getDocuments()
            
            let loadedPersonas = snapshot.documents.compactMap { doc -> Persona? in
                try? doc.data(as: Persona.self)
            }
            
            personas = loadedPersonas
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func loadAvailableTimes(date: Date, duration: TimeInterval, partnerPersonaId: String, partnerUserId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // No need for DispatchQueue in @MainActor
        self.isLoadingTimes = true
        self.availableTimeSlots = []
        
        do {
            // Get both user's calendar data
            let userCalendarData = try await db.collection("users").document(userId).collection("personas").document(partnerPersonaId).getDocument()
            let partnerCalendarData = try await db.collection("users").document(partnerUserId).collection("personas").document(partnerPersonaId).getDocument()
            
            // Check if we have calendar access for both users
            guard
                let userCalendarData = userCalendarData,
                let partnerCalendarData = partnerCalendarData,
                let userToken = userCalendarData.data()?["calendarAccessToken"] as? String,
                let partnerToken = partnerCalendarData.data()?["calendarAccessToken"] as? String
            else {
                throw NSError(
                    domain: "com.cheemhang.hangoutcreation",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Calendar access not available for both users"]
                )
            }
            
            // Get busy times for both users
            let userBusyTimes = try await calendarService.getBusyTimes(
                accessToken: userToken,
                date: date
            )
            
            let partnerBusyTimes = try await calendarService.getBusyTimes(
                accessToken: partnerToken,
                date: date
            )
            
            // Generate available time slots based on busy times
            let slots = generateTimeSlots(
                date: date,
                duration: duration,
                userBusyTimes: userBusyTimes,
                partnerBusyTimes: partnerBusyTimes
            )
            
            // No need for DispatchQueue in @MainActor
            self.availableTimeSlots = slots
            self.isLoadingTimes = false
        } catch {
            // For demo purposes, generate some fake time slots if calendar API fails
            #if DEBUG
            let slots = generateFakeTimeSlots(date: date, duration: duration)
            
            // No need for DispatchQueue in @MainActor
            self.availableTimeSlots = slots
            self.isLoadingTimes = false
            #else
            self.error = error
            self.isLoadingTimes = false
            #endif
        }
    }
    
    private func generateTimeSlots(
        date: Date,
        duration: TimeInterval,
        userBusyTimes: [(start: Date, end: Date)],
        partnerBusyTimes: [(start: Date, end: Date)]
    ) -> [TimeSlot] {
        // Combine all busy times
        let allBusyTimes = userBusyTimes + partnerBusyTimes
        
        // Start with standard time slots (9am to 9pm)
        let calendar = Calendar.current
        var timeSlots: [TimeSlot] = []
        
        // Create date components from the selected date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Create potential start times at 30-minute intervals
        for hour in 9..<21 {
            for minute in stride(from: 0, to: 60, by: 30) {
                var startComponents = dateComponents
                startComponents.hour = hour
                startComponents.minute = minute
                
                if let startTime = calendar.date(from: startComponents) {
                    let endTime = startTime.addingTimeInterval(duration)
                    
                    // Check if this time slot conflicts with any busy time
                    let hasConflict = allBusyTimes.contains { busyTime in
                        // Check for overlap
                        (startTime < busyTime.end && endTime > busyTime.start)
                    }
                    
                    if !hasConflict {
                        timeSlots.append(TimeSlot(startTime: startTime, endTime: endTime))
                    }
                }
            }
        }
        
        return timeSlots
    }
    
    private func generateFakeTimeSlots(date: Date, duration: TimeInterval) -> [TimeSlot] {
        // For development/demo purposes only
        let calendar = Calendar.current
        var slots: [TimeSlot] = []
        
        // Create date components from the selected date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Generate some time slots at different hours
        for hour in [9, 11, 13, 15, 17, 19] {
            var startComponents = dateComponents
            startComponents.hour = hour
            startComponents.minute = 0
            
            if let startTime = calendar.date(from: startComponents) {
                let endTime = startTime.addingTimeInterval(duration)
                slots.append(TimeSlot(startTime: startTime, endTime: endTime))
            }
        }
        
        return slots
    }
    
    func createHangout(with partnerPersona: Persona, type: HangoutType, timeSlot: TimeSlot) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        do {
            // Get the current user's default persona
            let userPersonas = try await db.collection("users").document(userId).collection("personas").getDocuments()
            let defaultPersona = userPersonas.documents.compactMap({ try? $0.data(as: Persona.self) }).first(where: { $0.isDefault })
            
            guard let userPersona = defaultPersona, let userPersonaId = userPersona.id else {
                throw NSError(domain: "com.cheemhang.hangout", code: 1, userInfo: [NSLocalizedDescriptionKey: "No default persona found"])
            }
            
            // Create the hangout data
            let hangout = Hangout(
                title: "\(type.rawValue) with \(partnerPersona.name)",
                description: "A \(type.rawValue.lowercased()) hangout between \(userPersona.name) and \(partnerPersona.name).",
                startDate: timeSlot.start,
                endDate: timeSlot.end,
                location: nil,
                creatorID: userId,
                creatorPersonaID: userPersonaId,
                inviteeID: partnerPersona.userID,
                inviteePersonaID: partnerPersona.id ?? "",
                status: .pending
            )
            
            // Save to Firestore
            let firestoreService = FirestoreService()
            let hangoutId = try await firestoreService.createHangout(hangout)
            
            print("Hangout created successfully with ID: \(hangoutId)")
            
            // Add to both users' calendars if they have calendar access
            try? await calendarService.createCalendarEvent(
                for: hangout,
                userIDs: [userId, partnerPersona.userID]
            )
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("Error creating hangout: \(error.localizedDescription)")
        }
    }
} 