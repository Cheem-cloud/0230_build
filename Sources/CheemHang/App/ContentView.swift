import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.default, value: authViewModel.isSignedIn)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
} 