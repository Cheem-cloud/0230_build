import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Set up notifications
        setupNotifications(application)
        
        return true
    }
    
    func setupNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permission
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if let error = error {
                    print("Error requesting notification permissions: \(error.localizedDescription)")
                }
                print("Notification permission granted: \(granted)")
            }
        )
        
        application.registerForRemoteNotifications()
        
        // Set up Firebase Messaging
        Messaging.messaging().delegate = self
    }
    
    // Handle device token for APNs
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        
        // Convert to string for debugging
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNs device token: \(token)")
    }
    
    // Handle failure to register for notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Handle FCM token refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Firebase registration token: \(token)")
            
            // Store token for later use
            UserDefaults.standard.set(token, forKey: "FCMToken")
        } else {
            print("FCM token is nil")
        }
    }
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Received notification in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Handling notification tap: \(userInfo)")
        
        // Process notification data
        if let hangoutID = userInfo["hangoutID"] as? String {
            print("Notification for hangout: \(hangoutID)")
            // TODO: Navigate to this hangout
        }
        
        completionHandler()
    }
} 