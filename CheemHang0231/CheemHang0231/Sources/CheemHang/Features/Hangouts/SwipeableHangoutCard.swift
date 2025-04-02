import SwiftUI

extension NotificationService {
    // Handle notification actions to accept or decline hangouts directly
    func handleNotificationAction(actionIdentifier: String, hangoutId: String) {
        print("🔔 Handling notification action: \(actionIdentifier) for hangout: \(hangoutId)")
        
        // Find the hangout and handle the action
        Task {
            do {
                let firestoreService = FirestoreService()
                if let hangout = try await firestoreService.getHangout(hangoutId) {
                    // Create the view model on the main actor
                    let hangoutsViewModel = await MainActor.run { HangoutsViewModel() }
                    
                    if actionIdentifier == "ACCEPT_ACTION" {
                        await hangoutsViewModel.updateHangoutStatus(hangout: hangout, newStatus: .accepted)
                        print("✅ Hangout accepted via notification: \(hangoutId)")
                        self.postLocalNotification(title: "Hangout Accepted", body: "You accepted the hangout request.")
                    } else if actionIdentifier == "DECLINE_ACTION" {
                        await hangoutsViewModel.updateHangoutStatus(hangout: hangout, newStatus: .declined)
                        print("❌ Hangout declined via notification: \(hangoutId)")
                        self.postLocalNotification(title: "Hangout Declined", body: "You declined the hangout request.")
                    }
                } else {
                    print("❌ Could not find hangout with ID: \(hangoutId)")
                }
            } catch {
                print("❌ Error handling notification action: \(error.localizedDescription)")
            }
        }
    }
} 