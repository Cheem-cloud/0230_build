import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            NavigationStack {
                Text("Hangouts")
                    .navigationTitle("Hangouts")
            }
            .tabItem {
                Label("Hangouts", systemImage: "calendar")
            }
            
            NavigationStack {
                Text("Personas")
                    .navigationTitle("Personas")
            }
            .tabItem {
                Label("Personas", systemImage: "person.crop.circle.fill")
            }
            
            NavigationStack {
                VStack {
                    Text("Profile")
                    
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "gear")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
} 