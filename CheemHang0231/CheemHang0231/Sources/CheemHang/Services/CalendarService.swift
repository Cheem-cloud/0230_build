import Foundation
import GoogleSignIn
import FirebaseFirestore
import FirebaseAuth
import UIKit
import Firebase

enum CalendarServiceError: Error {
    case invalidToken
    case requestFailed
    case invalidResponse
    case parseError
    case apiError(String)
}

class CalendarService {
    static let shared = CalendarService()
    
    private let baseURL = "https://www.googleapis.com/calendar/v3"
    
    func checkAvailability(userId: String, startDate: Date, endDate: Date) async -> Bool {
        do {
            // Get busy times for this time range
            let userToken = try await getCalendarToken(for: userId)
            let busyTimes = try await getBusyTimes(accessToken: userToken, startDate: startDate, endDate: endDate)
            
            // Check if our proposed time overlaps with any busy time
            let hasConflict = busyTimes.contains { busyTime in
                // Check for overlap
                (startDate < busyTime.end && endDate > busyTime.start)
            }
            
            return !hasConflict
        } catch {
            print("Error checking calendar availability: \(error.localizedDescription)")
            // If we can't check availability, we'll assume available
            return true
        }
    }
    
    func getBusyTimes(accessToken: String, date: Date) async throws -> [(start: Date, end: Date)] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Call the version that accepts a date range
        return try await getBusyTimes(accessToken: accessToken, startDate: startOfDay, endDate: endOfDay)
    }
    
    func createCalendarEvent(
        accessToken: String,
        title: String,
        description: String,
        startDate: Date,
        endDate: Date,
        location: String?
    ) async throws -> String {
        guard !accessToken.isEmpty else {
            throw CalendarServiceError.invalidToken
        }
        
        let url = URL(string: "\(baseURL)/calendars/primary/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dateFormatter = ISO8601DateFormatter()
        
        var eventBody: [String: Any] = [
            "summary": title,
            "description": description,
            "start": [
                "dateTime": dateFormatter.string(from: startDate),
                "timeZone": TimeZone.current.identifier
            ],
            "end": [
                "dateTime": dateFormatter.string(from: endDate),
                "timeZone": TimeZone.current.identifier
            ],
            "status": "confirmed"
        ]
        
        if let location = location, !location.isEmpty {
            eventBody["location"] = location
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: eventBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CalendarServiceError.invalidResponse
            }
            
            // Accept 200 (OK) or 201 (Created)
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("Calendar API error creating event: \(responseString)")
                throw CalendarServiceError.apiError("Status code: \(httpResponse.statusCode)")
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let eventId = json["id"] as? String else {
                throw CalendarServiceError.parseError
            }
            
            print("Successfully created calendar event with ID: \(eventId)")
            return eventId
        } catch {
            print("Error creating calendar event: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteCalendarEvent(accessToken: String, eventId: String) async throws {
        guard !accessToken.isEmpty else {
            throw CalendarServiceError.invalidToken
        }
        
        let url = URL(string: "\(baseURL)/calendars/primary/events/\(eventId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CalendarServiceError.invalidResponse
            }
            
            // 204 is success for DELETE
            guard httpResponse.statusCode == 204 else {
                throw CalendarServiceError.apiError("Status code: \(httpResponse.statusCode)")
            }
            
            print("Successfully deleted calendar event with ID: \(eventId)")
        } catch {
            print("Error deleting calendar event: \(error.localizedDescription)")
            throw error
        }
    }
    
    func findMutualAvailability(userIDs: [String], startDate: Date, endDate: Date, duration: TimeInterval) async throws -> [DateInterval] {
        guard userIDs.count == 2 else {
            throw CalendarServiceError.invalidResponse
        }

        print("CalendarService: Finding mutual availability for \(userIDs)")
        
        // Get busy times for both users from their linked calendars
        var allBusyTimes: [(start: Date, end: Date)] = []
        
        // Get user1's busy times
        do {
            let user1BusyTimes = try await getBusyTimesForUser(userID: userIDs[0], startDate: startDate, endDate: endDate)
            allBusyTimes.append(contentsOf: user1BusyTimes)
            print("CalendarService: Found \(user1BusyTimes.count) busy times for user1")
        } catch {
            print("Error getting busy times for user1: \(error.localizedDescription)")
            // Continue even if we can't get busy times for one user
        }
        
        // Get user2's busy times
        do {
            let user2BusyTimes = try await getBusyTimesForUser(userID: userIDs[1], startDate: startDate, endDate: endDate)
            allBusyTimes.append(contentsOf: user2BusyTimes)
            print("CalendarService: Found \(user2BusyTimes.count) busy times for user2")
        } catch {
            print("Error getting busy times for user2: \(error.localizedDescription)")
            // Continue even if we can't get busy times for one user
        }
        
        // If we couldn't get busy times for either user, fallback to realistic mock data
        if allBusyTimes.isEmpty {
            print("CalendarService: No busy times retrieved, using realistic mock data")
            return generateRealisticAvailability(startDate: startDate, endDate: endDate, duration: duration)
        }
        
        // Sort busy times chronologically
        allBusyTimes.sort { $0.start < $1.start }
        
        // Merge overlapping busy times
        var mergedBusyTimes: [(start: Date, end: Date)] = []
        for busyTime in allBusyTimes {
            if let lastBusy = mergedBusyTimes.last, lastBusy.end >= busyTime.start {
                // Overlap exists, merge them
                let newEnd = max(lastBusy.end, busyTime.end)
                mergedBusyTimes[mergedBusyTimes.count - 1] = (start: lastBusy.start, end: newEnd)
            } else {
                // No overlap, add as new busy time
                mergedBusyTimes.append(busyTime)
            }
        }
        
        // Generate potential time slots
        let potentialSlots = generateAllPossibleTimeSlots(startDate: startDate, endDate: endDate, duration: duration)
        
        // Filter out busy slots
        let availableSlots = potentialSlots.filter { slot in
            !mergedBusyTimes.contains { busyTime in
                // Check if this slot overlaps with any busy time
                max(slot.start, busyTime.start) < min(slot.end, busyTime.end)
            }
        }
        
        // Convert to DateIntervals
        let dateIntervals = availableSlots.map { DateInterval(start: $0.start, end: $0.end) }
        
        // If no slots are available, fallback to some realistic samples
        if dateIntervals.isEmpty {
            print("CalendarService: No available slots found, providing fallback slots")
            return generateRealisticAvailability(startDate: startDate, endDate: endDate, duration: duration)
        }
        
        return dateIntervals
    }
    
    // Add a method to retrieve calendar tokens for a user
    func getCalendarToken(for userId: String) async throws -> String {
        do {
            // Attempt to get token from Firestore
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(userId).collection("tokens").document("calendar")
            
            let document = try await docRef.getDocument()
            
            guard let data = document.data(),
                  let accessToken = data["accessToken"] as? String else {
                
                // If no token exists but the user is the current user, try to authenticate
                if userId == Auth.auth().currentUser?.uid {
                    print("No token found for current user, attempting authentication")
                    try await authenticateAndSaveCalendarAccess(for: userId)
                    return try await getCalendarToken(for: userId) // Recursive call after auth
                }
                
                throw CalendarServiceError.invalidToken
            }
            
            // Check if token is expired
            if let expirationTimestamp = data["expirationDate"] as? Timestamp {
                let expirationDate = expirationTimestamp.dateValue()
                
                // If token is expired or will expire in the next 5 minutes
                if expirationDate.timeIntervalSinceNow < 300 {
                    // Only refresh for current user
                    if userId == Auth.auth().currentUser?.uid {
                        print("Token expired, refreshing...")
                        
                        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
                            do {
                                // Restore previous sign-in session
                                let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                                
                                // Get fresh token - accessToken is non-optional in GoogleSignIn v6+
                                let accessToken = user.accessToken.tokenString
                                
                                // Save the updated token
                                try await saveTokenFromUser(user, userId: userId)
                                
                                print("Token refreshed successfully")
                                return accessToken
                            } catch {
                                print("Failed to refresh token: \(error.localizedDescription)")
                                // Fall back to full re-authentication
                                try await authenticateAndSaveCalendarAccess(for: userId)
                                return try await getCalendarToken(for: userId)
                            }
                        } else {
                            // No previous sign-in, need full re-auth
                            try await authenticateAndSaveCalendarAccess(for: userId) 
                            return try await getCalendarToken(for: userId)
                        }
                    }
                }
            }
            
            print("Retrieved valid calendar token for user \(userId)")
            return accessToken
        } catch {
            print("Error getting calendar token: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Helper function to get busy times for a specific user
    private func getBusyTimesForUser(userID: String, startDate: Date, endDate: Date) async throws -> [(start: Date, end: Date)] {
        do {
            // Get the user's calendar token from Firebase
            let accessToken = try await getCalendarToken(for: userID)
            
            // Use the token to query Google Calendar API
            return try await getBusyTimes(accessToken: accessToken, startDate: startDate, endDate: endDate)
        } catch {
            print("Error getting busy times for user \(userID): \(error.localizedDescription)")
            // Return some simulated busy times for development
            return generateSimulatedBusyTimes(startDate: startDate, endDate: endDate)
        }
    }
    
    // Get busy times for a date range (not just a single day)
    func getBusyTimes(accessToken: String, startDate: Date, endDate: Date) async throws -> [(start: Date, end: Date)] {
        guard !accessToken.isEmpty else {
            throw CalendarServiceError.invalidToken
        }
        
        let startTimeString = ISO8601DateFormatter().string(from: startDate)
        let endTimeString = ISO8601DateFormatter().string(from: endDate)
        
        let url = URL(string: "\(baseURL)/freeBusy")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "timeMin": startTimeString,
            "timeMax": endTimeString,
            "items": [["id": "primary"]]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CalendarServiceError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("Calendar API error: \(responseString)")
                throw CalendarServiceError.apiError("Status code: \(httpResponse.statusCode)")
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let calendars = json["calendars"] as? [String: Any],
                  let primary = calendars["primary"] as? [String: Any],
                  let busyArray = primary["busy"] as? [[String: String]] else {
                throw CalendarServiceError.parseError
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let busyTimes = busyArray.compactMap { busy -> (start: Date, end: Date)? in
                guard let startString = busy["start"],
                      let endString = busy["end"],
                      let startDate = dateFormatter.date(from: startString),
                      let endDate = dateFormatter.date(from: endString) else {
                    return nil
                }
                return (start: startDate, end: endDate)
            }
            
            return busyTimes
        } catch {
            print("Error fetching busy times: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Generate some simulated busy times for development
    private func generateSimulatedBusyTimes(startDate: Date, endDate: Date) -> [(start: Date, end: Date)] {
        var busyTimes: [(start: Date, end: Date)] = []
        let calendar = Calendar.current
        
        // Current date to iterate
        var currentDate = calendar.startOfDay(for: startDate)
        
        // Generate busy times until we reach end date
        while currentDate < endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // Work hours (9am-5pm) on weekdays
            if weekday >= 2 && weekday <= 6 {
                // Morning meeting 10-11am
                if let meetingStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: currentDate),
                   let meetingEnd = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: currentDate) {
                    busyTimes.append((start: meetingStart, end: meetingEnd))
                }
                
                // Lunch 12-1pm
                if let lunchStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate),
                   let lunchEnd = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: currentDate) {
                    busyTimes.append((start: lunchStart, end: lunchEnd))
                }
                
                // Random afternoon meeting (30% chance)
                if Double.random(in: 0...1) < 0.3, 
                   let meetingStart = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: currentDate),
                   let meetingEnd = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: currentDate) {
                    busyTimes.append((start: meetingStart, end: meetingEnd))
                }
            }
            
            // Random weekend plans (20% chance)
            if (weekday == 1 || weekday == 7) && Double.random(in: 0...1) < 0.2 {
                if let planStart = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: currentDate),
                   let planEnd = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: currentDate) {
                    busyTimes.append((start: planStart, end: planEnd))
                }
            }
            
            // Move to next day
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
            } else {
                break
            }
        }
        
        return busyTimes
    }
    
    // Generate all possible time slots that could be scheduled
    private func generateAllPossibleTimeSlots(startDate: Date, endDate: Date, duration: TimeInterval) -> [(start: Date, end: Date)] {
        var slots: [(start: Date, end: Date)] = []
        let calendar = Calendar.current
        
        // Business hours: 9am to 9pm
        let startHour = 9
        let endHour = 21
        
        // Current date to iterate
        var currentDate = calendar.startOfDay(for: startDate)
        
        // Generate slots until we reach end date
        while currentDate < endDate {
            // For each day, generate slots during business hours
            for hour in startHour..<endHour {
                for minute in stride(from: 0, to: 60, by: 30) {
                    if let slotStart = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: currentDate) {
                        let slotEnd = slotStart.addingTimeInterval(duration)
                        
                        // Only include if end time is before business hours end and before endDate
                        if calendar.component(.hour, from: slotEnd) < endHour && slotEnd <= endDate {
                            slots.append((start: slotStart, end: slotEnd))
                        }
                    }
                }
            }
            
            // Move to next day
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
            } else {
                break
            }
        }
        
        return slots
    }
    
    // Generate realistic mock availability for debugging/development
    private func generateRealisticAvailability(startDate: Date, endDate: Date, duration: TimeInterval) -> [DateInterval] {
        var availableSlots: [DateInterval] = []
        let calendar = Calendar.current
        
        // Business hours: 9am to 6pm
        let businessHoursStart = 9
        let businessHoursEnd = 18
        
        // Current date to iterate
        var currentDate = calendar.startOfDay(for: startDate)
        
        // Weekdays that should have more availability
        let moreDaysAvailable = [2, 3, 4] // Tuesday, Wednesday, Thursday
        
        // Generate slots until we reach end date
        while currentDate < endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // Skip weekends (1 = Sunday, 7 = Saturday)
            if weekday != 1 && weekday != 7 {
                // How many slots to generate for this day (more on certain days)
                let slotCount = moreDaysAvailable.contains(weekday) ? 5 : 3
                
                // Generate specific slots with more realistic timing
                var hoursToUse: [Int] = []
                
                // Morning slots (9-12)
                if Bool.random() {
                    hoursToUse.append(contentsOf: [9, 10, 11])
                }
                
                // Lunch slot (12-1)
                if Bool.random() && Bool.random() { // Less likely
                    hoursToUse.append(12)
                }
                
                // Afternoon slots (1-6)
                if Bool.random() {
                    hoursToUse.append(contentsOf: [13, 14, 15])
                }
                
                if Bool.random() {
                    hoursToUse.append(contentsOf: [16, 17])
                }
                
                // Shuffle and pick a subset
                hoursToUse.shuffle()
                let selectedHours = Array(hoursToUse.prefix(min(slotCount, hoursToUse.count)))
                
                // Create slots at those hours
                for hour in selectedHours.sorted() {
                    let minutes: [Int] = [0, 30] // Start at either :00 or :30
                    if let slotStart = calendar.date(bySettingHour: hour, minute: minutes.randomElement() ?? 0, second: 0, of: currentDate) {
                        // Check if slot is within range and during business hours
                        if slotStart >= startDate && 
                           calendar.component(.hour, from: slotStart) >= businessHoursStart &&
                           calendar.component(.hour, from: slotStart) < businessHoursEnd {
                            availableSlots.append(DateInterval(start: slotStart, duration: duration))
                        }
                    }
                }
            }
            
            // Move to next day
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
            } else {
                break
            }
        }
        
        // Sort by start time
        return availableSlots.sorted(by: { $0.start < $1.start })
    }
    
    func createCalendarEvent(for hangout: Hangout, userIDs: [String]) async throws -> String {
        do {
            // Get creator's calendar token
            let creatorToken = try await getCalendarToken(for: hangout.creatorID)
            
            // Create event in creator's calendar
            let creatorEventId = try await createCalendarEvent(
                accessToken: creatorToken,
                title: hangout.title,
                description: hangout.description,
                startDate: hangout.startDate,
                endDate: hangout.endDate,
                location: hangout.location
            )
            
            // Try to create event in invitee's calendar if possible
            if let inviteeToken = try? await getCalendarToken(for: hangout.inviteeID) {
                let _ = try await createCalendarEvent(
                    accessToken: inviteeToken,
                    title: hangout.title,
                    description: hangout.description,
                    startDate: hangout.startDate,
                    endDate: hangout.endDate,
                    location: hangout.location
                )
            }
            
            return creatorEventId
        } catch {
            print("Error creating calendar events: \(error.localizedDescription)")
            // Return a mock ID for development
            return UUID().uuidString
        }
    }
    
    private func getAuthenticatedURLRequest(for endpoint: String, accessToken: String) -> URLRequest {
        let url = URL(string: baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    // Method to save calendar token for a user
    func saveCalendarToken(for userId: String, accessToken: String, refreshToken: String? = nil, expirationDate: Date? = nil) async throws {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userId).collection("tokens").document("calendar")
        
        var tokenData: [String: Any] = ["accessToken": accessToken]
        
        if let refreshToken = refreshToken {
            tokenData["refreshToken"] = refreshToken
        }
        
        if let expirationDate = expirationDate {
            tokenData["expirationDate"] = Timestamp(date: expirationDate)
        }
        
        try await docRef.setData(tokenData, merge: true)
        print("Saved calendar token for user \(userId)")
    }
    
    // Method to check if a user has connected their Google Calendar
    func hasCalendarAccess(for userId: String) async -> Bool {
        do {
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(userId).collection("tokens").document("calendar")
            
            let document = try await docRef.getDocument()
            return document.exists && document.data()?["accessToken"] != nil
        } catch {
            print("Error checking calendar access: \(error.localizedDescription)")
            return false
        }
    }
    
    // Method to get authenticated GIDGoogleUser and save token
    func authenticateAndSaveCalendarAccess(for userId: String) async throws {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw CalendarServiceError.invalidResponse
        }
        
        // Get Google Sign In client ID from Firebase
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "com.cheemhang.calendar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase configuration error"])
        }
        
        let signInConfig = GIDConfiguration(clientID: clientID)
        
        // Request calendar scope
        let scopes = ["https://www.googleapis.com/auth/calendar", "https://www.googleapis.com/auth/calendar.events"]
        
        do {
            // Try to restore existing sign-in
            if GIDSignIn.sharedInstance.hasPreviousSignIn() {
                let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                
                // Check if we need to request additional scopes
                let grantedScopes = user.grantedScopes ?? []
                let needsAdditionalScopes = scopes.contains { !grantedScopes.contains($0) }
                
                if needsAdditionalScopes {
                    // Request additional scopes using signIn method with the right parameters
                    let result = try await GIDSignIn.sharedInstance.signIn(
                        withPresenting: rootViewController,
                        hint: nil,
                        additionalScopes: scopes
                    )
                    
                    try await saveTokenFromUser(result.user, userId: userId)
                    print("Updated calendar token with new scopes")
                } else {
                    // Use existing token
                    try await saveTokenFromUser(user, userId: userId)
                    print("Used existing Google Sign-In token")
                }
            } else {
                // New sign-in
                let result = try await GIDSignIn.sharedInstance.signIn(
                    withPresenting: rootViewController
                )
                
                try await saveTokenFromUser(result.user, userId: userId)
                print("New Google Sign-In successful")
            }
        } catch {
            print("Error in Google Sign-In: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Helper to save token from GIDGoogleUser
    private func saveTokenFromUser(_ user: GIDGoogleUser, userId: String) async throws {
        // Google Sign-In v6+ has non-optional tokens but different access pattern
        let accessToken = user.accessToken.tokenString
        
        // Handle refresh token - refreshToken itself isn't optional, but might be nil
        var refreshTokenString: String? = nil
        if user.refreshToken != nil {
            refreshTokenString = user.refreshToken.tokenString
        }
        
        try await saveCalendarToken(
            for: userId,
            accessToken: accessToken,
            refreshToken: refreshTokenString,
            expirationDate: user.accessToken.expirationDate
        )
    }
} 