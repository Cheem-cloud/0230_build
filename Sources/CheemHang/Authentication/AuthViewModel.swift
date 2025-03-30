import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

enum AuthState {
    case signedIn
    case signedOut
    case loading
}

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var error: Error?
    
    var isSignedIn: Bool {
        return user != nil
    }
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.authState = user != nil ? .signedIn : .signedOut
            }
        }
    }
    
    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.error = NSError(domain: "com.cheemhang.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase configuration error"])
            return
        }
        
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                throw NSError(domain: "com.cheemhang.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
            }
            
            // Start the sign-in flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            let user = result.user
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(domain: "com.cheemhang.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID token missing"])
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            try await Auth.auth().signIn(with: credential)
            
            // Get user's calendar access token
            // This is where we would set up Google Calendar API if needed
            let scopes = ["https://www.googleapis.com/auth/calendar"]
            await user.addScopes(scopes, presenting: rootViewController)
            
            // Now we should have calendar access
            let calendarAccessToken = user.accessToken.tokenString
            // Store this token somewhere for later use with Google Calendar API
            
        } catch {
            print("Error signing in with Google: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            self.error = error
        }
    }
} 