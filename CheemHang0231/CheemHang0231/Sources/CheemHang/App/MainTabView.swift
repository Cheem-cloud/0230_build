import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            NavigationStack {
                PartnerPersonasView()
            }
            .tabItem {
                Label("Partner", systemImage: "person.2.fill")
            }
            
            NavigationStack {
                HangoutsView()
            }
            .tabItem {
                Label("Hangouts", systemImage: "calendar")
            }
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
        .accentColor(.green) // Use standard green color instead of custom gold
        .onAppear {
            // Set the tab bar background color using standard UIColor
            UITabBar.appearance().backgroundColor = UIColor(red: 53/255, green: 94/255, blue: 59/255, alpha: 1.0) // hunter green
            UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.6)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
} 