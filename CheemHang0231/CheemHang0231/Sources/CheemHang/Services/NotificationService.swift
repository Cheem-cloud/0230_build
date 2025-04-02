import Foundation
import Firebase
import FirebaseMessaging
import FirebaseAuth
import FirebaseFunctions
import UIKit
import UserNotifications

class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private let db = Firestore.firestore()
    private let firestoreService = FirestoreService()
    
    enum NotificationType: String {
        case newHangoutRequest = "new_hangout_request"
        case hangoutAccepted = "hangout_accepted"
        case hangoutDeclined = "hangout_declined"
    }
    
    private override init() {
        super.init()
    }
    
    func setupNotifications() {
        // This is now handled by the AppDelegate
        // Do not request permissions directly here to avoid duplication
        
        let currentSettings = UNUserNotificationCenter.current().notificationSettings
        currentSettings { settings in
            print("Notification settings: \(settings)")
        }
    }
    
    func saveDeviceToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ Cannot save device token: User not logged in")
            return
        }
        
        Task {
            do {
                try await firestoreService.saveFCMToken(token, for: userId)
                print("✅ FCM token saved successfully via FirestoreService")
            } catch {
                print("❌ Error saving FCM token: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification Sending
    
    func sendNewHangoutRequestNotification(to userId: String, from creatorName: String, hangoutTitle: String, hangoutId: String) {
        let payload = createNotificationPayload(
            type: .newHangoutRequest,
            title: "New Hangout Request",
            body: "\(creatorName) wants to hangout with you!",
            data: ["hangoutId": hangoutId, "title": hangoutTitle]
        )
        
        sendNotification(to: userId, payload: payload)
    }
    
    func sendHangoutResponseNotification(to userId: String, accepted: Bool, responderName: String, hangoutTitle: String, hangoutId: String) {
        let type: NotificationType = accepted ? .hangoutAccepted : .hangoutDeclined
        let title = accepted ? "Hangout Accepted" : "Hangout Declined"
        let body = accepted 
            ? "\(responderName) accepted your hangout request!"
            : "\(responderName) declined your hangout request."
        
        let payload = createNotificationPayload(
            type: type,
            title: title,
            body: body,
            data: ["hangoutId": hangoutId, "title": hangoutTitle]
        )
        
        sendNotification(to: userId, payload: payload)
    }
    
    // MARK: - Helper Methods
    
    private func createNotificationPayload(type: NotificationType, title: String, body: String, data: [String: String]) -> [String: Any] {
        var payload: [String: Any] = [
            "notification": [
                "title": title,
                "body": body,
                "sound": "default"
            ],
            "data": [
                "type": type.rawValue
            ] as [String: Any]
        ]
        
        // Add any additional data
        var dataDict = payload["data"] as? [String: Any] ?? [:]
        for (key, value) in data {
            dataDict[key] = value
        }
        payload["data"] = dataDict
        
        return payload
    }
    
    private func sendNotification(to userId: String, payload: [String: Any]) {
        // Get the user's FCM token
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists,
                  let userData = snapshot.data(),
                  let fcmToken = userData["fcmToken"] as? String else {
                print("❌ Cannot send notification: FCM token not found for user \(userId)")
                return
            }
            
            // Send notification via Firebase Cloud Functions
            print("📲 Sending notification to token: \(fcmToken)")
            print("📲 Payload: \(payload)")
            
            let functions = Functions.functions()
            functions.httpsCallable("sendPushNotification").call(["token": fcmToken, "payload": payload]) { result, error in
                if let error = error {
                    print("❌ Error sending notification: \(error.localizedDescription)")
                    
                    // Fallback to local notification for testing/development
                    if let notificationDict = payload["notification"] as? [String: Any],
                       let title = notificationDict["title"] as? String,
                       let body = notificationDict["body"] as? String {
                        self.postLocalNotification(title: title, body: body)
                        print("⚠️ Used local notification as fallback due to FCM error")
                    }
                } else {
                    print("✅ Push notification sent successfully via Firebase")
                }
            }
        }
    }
    
    // MARK: - Local Notifications (for testing)
    
    func postLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Add a category identifier for notification actions
        content.categoryIdentifier = "HANGOUT_INVITATION"
        
        // Create a unique identifier for this notification
        let identifier = UUID().uuidString
        
        // Create a trigger - 1 second delay for testing
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create a request with the content and trigger
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Add notification actions if appropriate
        addNotificationActions()
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error posting local notification: \(error.localizedDescription)")
            } else {
                print("✅ Local notification scheduled successfully with ID: \(identifier)")
            }
        }
        
        // For testing/demo purposes, if app is in foreground, also show an alert
        // In a real app, the UNUserNotificationCenterDelegate handles this
        if UIApplication.shared.applicationState == .active {
            print("📱 App is active - notification would appear as banner")
        }
    }
    
    // Add notification action buttons
    private func addNotificationActions() {
        // Accept action
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_ACTION",
            title: "Accept",
            options: [.foreground]
        )
        
        // Decline action
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_ACTION",
            title: "Decline",
            options: [.destructive, .foreground]
        )
        
        // Create category with actions
        let hangoutCategory = UNNotificationCategory(
            identifier: "HANGOUT_INVITATION",
            actions: [acceptAction, declineAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([hangoutCategory])
    }
    
    // Function to display a test notification immediately
    func sendTestNotification() {
        postLocalNotification(
            title: "Test Notification",
            body: "This is a test notification to verify push notifications are working!"
        )
        print("🧪 Test notification sent")
        
        // Test Firebase Functions connectivity
        testFirebaseFunctionsConnectivity()
    }
    
    // Test if we can connect to Firebase Functions
    private func testFirebaseFunctionsConnectivity() {
        let functions = Functions.functions()
        functions.httpsCallable("ping").call() { (result, error) in
            if let error = error {
                print("❌ Firebase Functions connectivity test failed: \(error.localizedDescription)")
                print("❌ You may need to create a simple 'ping' function in Firebase and deploy it")
            } else {
                print("✅ Firebase Functions connectivity test succeeded!")
                print("✅ Result: \(String(describing: result?.data))")
            }
        }
    }
    
    func scheduleLocalNotification(title: String, body: String, userInfo: [String: Any] = [:], delay: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Add any custom data
        content.userInfo = userInfo
        
        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        
        // Create request
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error.localizedDescription)")
            } else {
                print("Local notification scheduled with ID: \(identifier)")
            }
        }
    }
    
    func scheduleHangoutNotification(hangoutTitle: String, partnerName: String, date: Date, hangoutId: String) {
        // Create notification content
        let title = "Upcoming Hangout"
        let body = "Your hangout '\(hangoutTitle)' with \(partnerName) is coming up!"
        let userInfo = ["hangoutID": hangoutId]
        
        // Calculate delay (5 minutes before the hangout)
        let delay = max(0, date.timeIntervalSinceNow - 5 * 60)
        
        // Schedule notification
        scheduleLocalNotification(title: title, body: body, userInfo: userInfo, delay: delay)
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // For foreground notifications - show banner, play sound, and update badge
        // iOS 14 and later supports .banner (iOS 13 used .alert)
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
        print("🔔 Notification will be presented while app is in foreground")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        print("🔔 Notification response received: \(response.actionIdentifier)")
        print("🔔 Notification userInfo: \(userInfo)")
        
        // Extract hangout ID if available
        let hangoutId = (userInfo["hangoutId"] as? String) ?? 
                        (userInfo["data"] as? [String: Any])?["hangoutId"] as? String
        
        // Handle custom actions
        if response.actionIdentifier == "ACCEPT_ACTION" {
            print("🔔 User tapped Accept button")
            if let hangoutId = hangoutId {
                // Handle the accept action
                handleNotificationAction(actionIdentifier: "ACCEPT_ACTION", hangoutId: hangoutId)
            }
        } else if response.actionIdentifier == "DECLINE_ACTION" {
            print("🔔 User tapped Decline button")
            if let hangoutId = hangoutId {
                // Handle the decline action
                handleNotificationAction(actionIdentifier: "DECLINE_ACTION", hangoutId: hangoutId)
            }
        } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // Standard tap on notification (not on an action button)
            if let notificationType = (userInfo["type"] as? String) ?? (userInfo["data"] as? [String: Any])?["type"] as? String,
               let hangoutId = hangoutId {
                print("🔔 Notification tapped: Type=\(notificationType), HangoutId=\(hangoutId)")
                
                // Here you would navigate to the appropriate screen
                // Since we don't have direct access to the navigation stack, we'll post a notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenHangoutFromNotification"),
                    object: nil,
                    userInfo: ["hangoutId": hangoutId]
                )
            }
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension NotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("✅ Firebase registration token: \(token)")
            saveDeviceToken(token)
        } else {
            print("❌ FCM token is nil")
        }
    }
} 