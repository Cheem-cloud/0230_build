import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var forceAuthUpdate = false
    
    var body: some View {
        ZStack {
            if forceAuthUpdate {
                // Force the auth view to show if we determined there's an issue
                AuthView()
                    .onAppear {
                        print("ContentView: AuthView appeared (forced)")
                    }
            } else {
                switch authViewModel.authState {
                case .signedIn:
                    MainTabView()
                        .onAppear {
                            print("ContentView: MainTabView appeared")
                        }
                case .signedOut:
                    AuthView()
                        .onAppear {
                            print("ContentView: AuthView appeared")
                        }
                case .loading:
                    ZStack {
                        // Background with hunter green
                        Color.hunterGreen
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                                .scaleEffect(1.5)
                            
                            Text("Loading authentication state...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                    .onAppear {
                        print("ContentView: Loading view appeared")
                    }
                }
            }
        }
        .onAppear {
            print("ContentView: Real app ContentView appeared, auth state: \(String(describing: authViewModel.authState))")
            
            // Force update auth state after a delay if still loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if case .loading = authViewModel.authState {
                    print("ContentView: Auth state still loading after delay, forcing update")
                    authViewModel.authState = .signedOut
                }
                
                // If we're seeing any issues with auth, force the auth view to show
                if authViewModel.error != nil {
                    print("ContentView: Found auth error, forcing auth view to show")
                    forceAuthUpdate = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
} 