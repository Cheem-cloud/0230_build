import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var hangoutsViewModel = HangoutsViewModel()
    @State private var pendingRequestsCount = 0
    
    var body: some View {
        TabView {
            NavigationStack {
                PartnerPersonasView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Date", systemImage: "person.2.fill")
            }
            
            NavigationStack {
                HangoutsView()
                    .environmentObject(hangoutsViewModel)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Hangouts", systemImage: "calendar")
            }
            .badge(pendingRequestsCount)
            
            NavigationStack {
                ProfileView()
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
        .accentColor(.mutedGold) // Change accent color to muted gold
        // Add padding at the bottom to float the tab bar
        .safeAreaInset(edge: .bottom) {
            Spacer()
                .frame(height: 40) // This creates space below the tab bar
        }
        .onAppear {
            // Set up floating pill-style tab bar
            if #available(iOS 15.0, *) {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithTransparentBackground()
                
                // Add a background blur
                tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
                
                // Add a shadow
                tabBarAppearance.shadowColor = UIColor.black.withAlphaComponent(0.3)
                
                // Customize unselected and selected colors to white
                tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.7)
                tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.7)]
                
                tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
                
                UITabBar.appearance().standardAppearance = tabBarAppearance
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                
                // Make the tab bar items more compact
                UITabBar.appearance().itemSpacing = 20
                
                // Add rounded corners and margin styling in a separate method
                DispatchQueue.main.async {
                    self.styleTabBarAsPill()
                }
            } else {
                // Fallback for older iOS versions
                UITabBar.appearance().backgroundColor = UIColor.systemBackground
                UITabBar.appearance().unselectedItemTintColor = UIColor(Color.burgundy)
            }
            
            // Make navigation bars look like floating pills too
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            
            // Add rounded corners
            appearance.backgroundColor = .clear
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().tintColor = UIColor(Color.hunterGreenLight)
            
            // Load hangouts to check for pending requests
            loadPendingRequestsCount()
        }
    }
    
    private func styleTabBarAsPill() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let tabBars = window.rootViewController?.view.subviews.filter({ $0 is UITabBar }) {
            if let tabBar = tabBars.first as? UITabBar {
                // Physically move the tab bar up much more aggressively
                let bottomOffset: CGFloat = 40 // Much larger distance from bottom
                
                // Adjust the actual position of the tab bar
                var frame = tabBar.frame
                frame.origin.y = frame.origin.y - bottomOffset
                tabBar.frame = frame
                
                // Create a shaped layer for the pill effect
                let shapeLayer = CAShapeLayer()
                
                // Increase side margins to create more black space on sides
                let width = tabBar.frame.width - 80 // Much more margin on both sides
                let height = tabBar.frame.height  // Use full height
                
                let bezierPath = UIBezierPath(
                    roundedRect: CGRect(
                        x: 40, // Increased left margin
                        y: 0, // Start from top
                        width: width,
                        height: height
                    ),
                    cornerRadius: height / 2 // Fully rounded corners
                )
                
                shapeLayer.path = bezierPath.cgPath
                shapeLayer.fillColor = UIColor(Color.deepRed).cgColor
                shapeLayer.shadowColor = UIColor.black.cgColor
                shapeLayer.shadowOffset = CGSize(width: 0, height: 3)
                shapeLayer.shadowOpacity = 0.4
                shapeLayer.shadowRadius = 10
                
                // Replace the background with our custom shape
                if let oldShapeLayer = tabBar.layer.sublayers?.first(where: { $0 is CAShapeLayer }) {
                    oldShapeLayer.removeFromSuperlayer()
                }
                
                tabBar.layer.insertSublayer(shapeLayer, at: 0)
                tabBar.backgroundColor = .clear
                tabBar.backgroundImage = UIImage()
                tabBar.shadowImage = UIImage()
                
                // Ensure the tab bar is completely transparent
                tabBar.isTranslucent = true
                
                // Style the navigation bars to match the pill look
                styleNavigationBarsAsPills()
            }
        }
    }
    
    private func styleNavigationBarsAsPills() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Add a custom background view to be a pill shape
        let navBarHeight: CGFloat = 44 // Standard height
        let horizontalMargin: CGFloat = 40
        
        let navPillAppearance = UINavigationBarAppearance()
        navPillAppearance.configureWithTransparentBackground()
        
        // Custom background view in the title view
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(Color.hunterGreen)
        backgroundView.layer.cornerRadius = navBarHeight / 2
        backgroundView.layer.masksToBounds = true
        backgroundView.frame = CGRect(x: horizontalMargin, y: 6, width: UIScreen.main.bounds.width - (horizontalMargin * 2), height: navBarHeight - 12)
        
        // Add shadow
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 3)
        backgroundView.layer.shadowOpacity = 0.4
        backgroundView.layer.shadowRadius = 8
        
        // Configure title text attributes
        navPillAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        
        // Apply the custom appearance globally
        UINavigationBar.appearance().standardAppearance = navPillAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navPillAppearance
        UINavigationBar.appearance().compactAppearance = navPillAppearance
        
        // Add a method to inject the pill background view to each navigation bar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Update each navigation controller's navigation bar
            if let windows = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows {
                
                for window in windows {
                    if let rootVC = window.rootViewController {
                        self.applyPillToAllNavigationBars(rootVC, horizontalMargin: horizontalMargin)
                    }
                }
            }
        }
    }
    
    private func applyPillToAllNavigationBars(_ viewController: UIViewController, horizontalMargin: CGFloat) {
        // Apply pill to the current view controller's navigation bar if it has one
        if let navController = viewController as? UINavigationController {
            applyPillToNavigationBar(navController.navigationBar, horizontalMargin: horizontalMargin)
        } else if let navController = viewController.navigationController {
            applyPillToNavigationBar(navController.navigationBar, horizontalMargin: horizontalMargin)
        }
        
        // Recursively apply to child view controllers
        for child in viewController.children {
            applyPillToAllNavigationBars(child, horizontalMargin: horizontalMargin)
        }
    }
    
    private func applyPillToNavigationBar(_ navigationBar: UINavigationBar, horizontalMargin: CGFloat) {
        // Create a pill-shaped background for the navigation bar
        let pillView = UIView()
        pillView.backgroundColor = UIColor(Color.deepRed)
        pillView.layer.cornerRadius = 22 // Half of standard height for pill shape
        
        // Size it with margins
        let pillWidth = navigationBar.frame.width - (horizontalMargin * 2)
        pillView.frame = CGRect(x: horizontalMargin, y: 4, width: pillWidth, height: 44 - 8)
        
        // Add shadow
        pillView.layer.shadowColor = UIColor.black.cgColor
        pillView.layer.shadowOffset = CGSize(width: 0, height: 2)
        pillView.layer.shadowOpacity = 0.3
        pillView.layer.shadowRadius = 6
        pillView.layer.masksToBounds = false
        
        // Add to navbar
        navigationBar.addSubview(pillView)
        navigationBar.sendSubviewToBack(pillView)
    }
    
    private func loadPendingRequestsCount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("hangouts")
            .whereField("inviteeID", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error listening for pending requests: \(error.localizedDescription)")
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.pendingRequestsCount = count
                }
            }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
} 