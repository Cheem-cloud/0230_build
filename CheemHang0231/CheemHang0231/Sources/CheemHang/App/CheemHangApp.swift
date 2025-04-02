import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseMessaging
import UIKit

@main
struct UnhingedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var personaManager = PersonaManager.shared
    @StateObject var authManager = AuthManager.shared
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSplash = true
    
    init() {
        print("UnhingedApp: Initializing app")
        
        // Configure Firebase
        if FirebaseApp.app() == nil {
            print("UnhingedApp: Configuring Firebase")
            FirebaseApp.configure()
        } else {
            print("UnhingedApp: Firebase already configured")
        }
        
        // Check if we can get the client ID (to verify Firebase config)
        if let clientID = FirebaseApp.app()?.options.clientID {
            print("UnhingedApp: Firebase clientID found: \(clientID)")
        } else {
            print("UnhingedApp: ERROR - Firebase clientID not found")
        }
        
        // Check if user is already signed in
        if let user = Auth.auth().currentUser {
            print("UnhingedApp: User already signed in: \(user.uid)")
        } else {
            print("UnhingedApp: No signed-in user found")
        }
        
        // Set up notifications
        NotificationService.shared.setupNotifications()
        
        // Apply theme
        configureTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView()
                    .environmentObject(authViewModel)
                    .preferredColorScheme(.dark)
                    .onAppear {
                        print("UnhingedApp: SplashView appeared")
                        // Increase splash screen timeout to make it more visible
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                print("UnhingedApp: Dismissing splash screen")
                                showSplash = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .environmentObject(authViewModel)
                    .onOpenURL { url in
                        print("UnhingedApp: Handling URL: \(url)")
                        print("UnhingedApp: URL scheme: \(url.scheme ?? "none")")
                        print("UnhingedApp: URL host: \(url.host ?? "none")")
                        print("UnhingedApp: URL path: \(url.path)")
                        
                        // Check if this is a Google Sign-in callback URL
                        if url.scheme?.contains("googleusercontent") == true || 
                           url.scheme?.starts(with: "com.googleusercontent") == true {
                            print("UnhingedApp: Detected Google Sign-in URL, passing to GIDSignIn")
                            GIDSignIn.sharedInstance.handle(url)
                        } else {
                            print("UnhingedApp: URL not recognized as Google Sign-in URL")
                        }
                    }
                    .onAppear {
                        print("UnhingedApp: ContentView appeared")
                    }
                    .preferredColorScheme(.dark) // Force dark mode for better contrast with colors
            }
        }
    }
    
    private func configureTheme() {
        // Configure the appearance of navigation bars
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = UIColor.clear
        navigationBarAppearance.shadowColor = .clear
        
        // Set title text attributes
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        // Apply to UINavigationBar
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.softPink)
        
        // Configure the appearance of tab bars
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.clear
        tabBarAppearance.shadowColor = .clear
        
        // Apply to UITabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor.white
        
        // Form controls appearance
        UITextField.appearance().tintColor = UIColor(Color.deepRed)
        UITextView.appearance().tintColor = UIColor(Color.deepRed)
        
        // Segmented controls
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.deepRed)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(Color.deepRed)], for: .normal)
        
        // Switch appearance
        UISwitch.appearance().onTintColor = UIColor(Color.deepRed)
        UISwitch.appearance().thumbTintColor = UIColor.white
        
        // Button appearance
        UIButton.appearance().tintColor = UIColor(Color.deepRed)
    }
} 