import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@MainActor
class HangoutsViewModel: ObservableObject {
    @Published var hangouts: [Hangout] = []
    @Published var personaDetails: [String: Persona] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firestoreService = FirestoreService()
    private let calendarService = CalendarService()
    
    var pendingHangouts: [Hangout] {
        hangouts.filter { $0.status == .pending }
            .sorted { $0.startDate < $1.startDate }
    }
    
    var upcomingHangouts: [Hangout] {
        let now = Date()
        return hangouts.filter { $0.status == .accepted && $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
    }
    
    var declinedHangouts: [Hangout] {
        return hangouts.filter { $0.status == .declined }
            .sorted { $0.startDate > $1.startDate } // Most recent first
    }
    
    var pastHangouts: [Hangout] {
        let now = Date()
        return hangouts.filter { 
            ($0.status == .accepted && $0.startDate < now) || 
            $0.status == .completed || 
            $0.status == .cancelled
        }
        .sorted { $0.startDate > $1.startDate } // Most recent first
    }
    
    func loadHangouts() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("🔄 HangoutsViewModel - Starting loadHangouts() for user: \(userId)")
        isLoading = true
        
        Task {
            do {
                let fetchedHangouts = try await firestoreService.getHangouts(for: userId)
                print("✅ HangoutsViewModel - Loaded \(fetchedHangouts.count) hangouts")
                
                // Pre-load all personas for each hangout
                var allPersonaIds = Set<String>()
                for hangout in fetchedHangouts {
                    allPersonaIds.insert(hangout.creatorPersonaID)
                    allPersonaIds.insert(hangout.inviteePersonaID)
                }
                
                print("🧩 HangoutsViewModel - Need to load \(allPersonaIds.count) personas")
                
                // Fetch all needed personas
                var personaMap: [String: Persona] = [:]
                for personaId in allPersonaIds {
                    // Determine the user ID for this persona by checking each hangout
                    for hangout in fetchedHangouts {
                        if hangout.creatorPersonaID == personaId {
                            // This is a creator persona
                            if let persona = try? await firestoreService.getPersona(personaId, for: hangout.creatorID) {
                                personaMap[personaId] = persona
                                print("DEBUG: Loaded creator persona: \(persona.name) for ID \(personaId)")
                                break
                            }
                        } else if hangout.inviteePersonaID == personaId {
                            // This is an invitee persona
                            if let persona = try? await firestoreService.getPersona(personaId, for: hangout.inviteeID) {
                                personaMap[personaId] = persona
                                print("DEBUG: Loaded invitee persona: \(persona.name) for ID \(personaId)")
                                break
                            }
                        }
                    }
                }
                
                print("👤 HangoutsViewModel - Loaded \(personaMap.count) personas")
                
                DispatchQueue.main.async {
                    self.hangouts = fetchedHangouts
                    self.personaDetails = personaMap
                    self.isLoading = false
                    print("🔄 HangoutsViewModel - UI updated with \(self.hangouts.count) hangouts")
                    print("📊 Pending: \(self.pendingHangouts.count), Upcoming: \(self.upcomingHangouts.count), Declined: \(self.declinedHangouts.count), Past: \(self.pastHangouts.count)")
                    
                    // Update app badge count with number of pending requests
                    self.updateAppBadgeCount()
                }
            } catch {
                print("❌ HangoutsViewModel - Error loading hangouts: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateAppBadgeCount() {
        // Count pending hangouts where current user is the invitee (requests to respond to)
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let pendingForUser = hangouts.filter { 
            $0.status == .pending && $0.inviteeID == currentUserId
        }
        
        // Set the app badge to the number of pending requests
        UNUserNotificationCenter.current().setBadgeCount(pendingForUser.count) { error in
            if let error = error {
                print("❌ Error setting badge count: \(error.localizedDescription)")
            } else {
                print("✅ App badge count updated to \(pendingForUser.count)")
            }
        }
    }
    
    func createHangout(title: String, description: String, startDate: Date, endDate: Date, location: String?, inviteeID: String, creatorPersonaID: String, inviteePersonaID: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "com.cheemhang.hangoutsviewmodel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let newHangout = Hangout(
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location,
            creatorID: userId,
            creatorPersonaID: creatorPersonaID,
            inviteeID: inviteeID,
            inviteePersonaID: inviteePersonaID
        )
        
        // Check calendar availability before creating the hangout
        let isAvailable = await calendarService.checkAvailability(
            userId: userId, 
            startDate: startDate, 
            endDate: endDate
        )
        
        if !isAvailable {
            throw NSError(
                domain: "com.cheemhang.hangoutsviewmodel", 
                code: -2, 
                userInfo: [NSLocalizedDescriptionKey: "You are not available during this time. Please check your calendar."]
            )
        }
        
        // Create hangout in Firestore
        let hangoutId = try await firestoreService.createHangout(newHangout)
        print("Created hangout with ID: \(hangoutId)")
        
        // Add to calendar if user has calendar permissions
        if let user = try? await firestoreService.getUser(id: userId),
           let calendarAccessToken = user.calendarAccessToken {
            let eventId = try? await calendarService.createCalendarEvent(
                accessToken: calendarAccessToken,
                title: title,
                description: description,
                startDate: startDate,
                endDate: endDate,
                location: location
            )
            
            if let eventId = eventId, let _ = newHangout.id {
                // Update hangout with calendar event ID
                var updatedHangout = newHangout
                updatedHangout.calendarEventID = eventId
                try? await firestoreService.updateHangout(updatedHangout)
            }
        }
    }
    
    func updateHangoutStatus(hangout: Hangout, newStatus: HangoutStatus) async {
        guard let hangoutId = hangout.id else { return }
        
        do {
            var updatedHangout = hangout
            updatedHangout.status = newStatus
            updatedHangout.updatedAt = Date()
            
            try await firestoreService.updateHangout(updatedHangout)
            
            // If the status changed to accepted or declined, send notification to creator
            if (newStatus == .accepted || newStatus == .declined) {
                // Get the responder's persona name
                let responderPersonaId = hangout.inviteePersonaID
                if let responderPersona = personaDetails[responderPersonaId] {
                    // Send notification to the creator
                    NotificationService.shared.sendHangoutResponseNotification(
                        to: hangout.creatorID,
                        accepted: newStatus == .accepted,
                        responderName: responderPersona.name,
                        hangoutTitle: hangout.title,
                        hangoutId: hangoutId
                    )
                }
            }
            
            // If the hangout was accepted, add to calendar
            if newStatus == .accepted,
               let user = try? await firestoreService.getUser(id: hangout.inviteeID),
               let calendarAccessToken = user.calendarAccessToken,
               hangout.calendarEventID == nil {
                
                let eventId = try? await calendarService.createCalendarEvent(
                    accessToken: calendarAccessToken,
                    title: hangout.title,
                    description: hangout.description,
                    startDate: hangout.startDate,
                    endDate: hangout.endDate,
                    location: hangout.location
                )
                
                if let eventId = eventId {
                    // Update hangout with calendar event ID
                    var calendarUpdatedHangout = updatedHangout
                    calendarUpdatedHangout.calendarEventID = eventId
                    try? await firestoreService.updateHangout(calendarUpdatedHangout)
                }
            }
            
            // If the hangout was declined or cancelled, remove from calendar
            if (newStatus == .declined || newStatus == .cancelled),
               let calendarEventID = hangout.calendarEventID {
                
                // Remove from creator's calendar
                if let creatorUser = try await firestoreService.getUser(id: hangout.creatorID),
                   let creatorToken = creatorUser.calendarAccessToken {
                    try await calendarService.deleteCalendarEvent(
                        accessToken: creatorToken,
                        eventId: calendarEventID
                    )
                }
                
                // Remove from invitee's calendar
                if let inviteeUser = try await firestoreService.getUser(id: hangout.inviteeID),
                   let inviteeToken = inviteeUser.calendarAccessToken {
                    try await calendarService.deleteCalendarEvent(
                        accessToken: inviteeToken,
                        eventId: calendarEventID
                    )
                }
            }
            
            DispatchQueue.main.async {
                self.loadHangouts()
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func deleteHangout(hangout: Hangout) async {
        guard let hangoutId = hangout.id else { return }
        
        do {
            // If there's a calendar event, delete it first
            if let calendarEventID = hangout.calendarEventID,
               let user = try? await firestoreService.getUser(id: hangout.creatorID),
               let calendarAccessToken = user.calendarAccessToken {
                
                try await calendarService.deleteCalendarEvent(
                    accessToken: calendarAccessToken,
                    eventId: calendarEventID
                )
            }
            
            try await firestoreService.deleteHangout(hangoutId)
            
            DispatchQueue.main.async {
                self.loadHangouts()
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func cancelHangout(_ hangout: Hangout) async {
        guard let _ = hangout.id else { return }
        
        do {
            // Update hangout status
            var updatedHangout = hangout
            updatedHangout.status = .cancelled
            updatedHangout.updatedAt = Date()
            
            try await firestoreService.updateHangout(updatedHangout)
            
            // Remove from calendar if there's a calendar event
            if let calendarEventID = hangout.calendarEventID {
                // Remove from creator's calendar
                if let creatorUser = try await firestoreService.getUser(id: hangout.creatorID),
                   let creatorToken = creatorUser.calendarAccessToken {
                    try await calendarService.deleteCalendarEvent(
                        accessToken: creatorToken,
                        eventId: calendarEventID
                    )
                }
                
                // Remove from invitee's calendar
                if let inviteeUser = try await firestoreService.getUser(id: hangout.inviteeID),
                   let inviteeToken = inviteeUser.calendarAccessToken {
                    try await calendarService.deleteCalendarEvent(
                        accessToken: inviteeToken,
                        eventId: calendarEventID
                    )
                }
            }
            
            DispatchQueue.main.async {
                self.loadHangouts()
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
} 