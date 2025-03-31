import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
struct CheemHangMainApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        print("CheemHangApp: Initializing app")
        
        // Configure Firebase
        if FirebaseApp.app() == nil {
            print("CheemHangApp: Configuring Firebase")
            FirebaseApp.configure()
        } else {
            print("CheemHangApp: Firebase already configured")
        }
        
        // Check if we can get the client ID (to verify Firebase config)
        if let clientID = FirebaseApp.app()?.options.clientID {
            print("CheemHangApp: Firebase clientID found: \(clientID)")
        } else {
            print("CheemHangApp: ERROR - Firebase clientID not found")
        }
        
        // Check if user is already signed in
        if let user = Auth.auth().currentUser {
            print("CheemHangApp: User already signed in: \(user.uid)")
        } else {
            print("CheemHangApp: No signed-in user found")
        }
        
        // Apply hunter green theme
        configureAppTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    print("CheemHangApp: Handling URL: \(url)")
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    print("CheemHangApp: ContentView appeared")
                }
                .preferredColorScheme(.dark) // Force dark mode for better contrast with green
        }
    }
    
    private func configureAppTheme() {
        // Apply global app theme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.hunterGreen)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.white
        
        // Configure tab bar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.hunterGreen)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(Color.hunterGreenLight)
        
        // Form controls
        UITextField.appearance().tintColor = UIColor(Color.hunterGreenLight)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.hunterGreenLight)
        UISwitch.appearance().onTintColor = UIColor(Color.hunterGreenLight)
    }
} 