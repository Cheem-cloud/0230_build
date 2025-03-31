import SwiftUI
import GoogleSignInSwift

struct AuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isSigningIn = false
    
    var body: some View {
        ZStack {
            // Background gradient - moved to ZStack to ensure it fills the entire screen
            LinearGradient(
                colors: [Color.hunterGreen, Color.hunterGreenDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 24) {
                Spacer()
                
                // App logo/branding
                Image(systemName: "person.2.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(Color.goldAccent)
                
                Text("CheemHang")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Seamlessly plan hangouts with your favorite people")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Sign in button
                GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: isSigningIn ? .pressed : .normal)) {
                    Task {
                        isSigningIn = true
                        await authViewModel.signInWithGoogle()
                        isSigningIn = false
                    }
                }
                .frame(width: 280, height: 50)
                
                if let error = authViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer()
            }
            .padding(.horizontal) // Only pad horizontally, not vertically
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill the available space
        }
        .edgesIgnoringSafeArea(.all) // Ensure we ignore all safe areas
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
} 