import SwiftUI
import GoogleSignInSwift

struct AuthView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isSigningIn = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App logo/branding
            Image(systemName: "person.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            
            Text("CheemHang")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Seamlessly plan hangouts with your favorite people")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Sign in button
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .light, style: .wide, state: isSigningIn ? .pressed : .normal)) {
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
        .padding()
        .background {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
} 