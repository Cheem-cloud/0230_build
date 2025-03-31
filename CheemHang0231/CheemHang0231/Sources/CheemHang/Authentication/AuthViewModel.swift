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

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var authState: AuthState = .loading
    @Published var error: Error?
    @Published var isLoading: Bool = false
    
    // Store auth state listener handle
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    var isSignedIn: Bool {
        return user != nil
    }
    
    init() {
        print("AuthViewModel: Initializing")
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        print("AuthViewModel: Setting up auth state listener")
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.authState = user != nil ? .signedIn : .signedOut
                print("AuthViewModel: Auth state changed to \(user != nil ? "signedIn" : "signedOut")")
            }
        }
    }
    
    func signInWithGoogle() async {
        print("AuthViewModel: Starting Google sign-in flow")
        isLoading = true
        
        // Use defer to ensure isLoading is set to false when the function exits
        defer {
            isLoading = false
        }
        
        // Get the client ID from GoogleService-Info.plist
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("AuthViewModel: Firebase client ID not found")
            self.error = NSError(domain: "com.cheemhang.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase configuration error"])
            return
        }
        
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            // Get the key window from the active scene - this is guaranteed to be on the main thread with @MainActor
            let windowScene = UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first as? UIWindowScene
            
            guard let rootViewController = windowScene?.windows.first?.rootViewController else {
                print("AuthViewModel: No root view controller found")
                throw NSError(domain: "com.cheemhang.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
            }
            
            print("AuthViewModel: Presenting Google sign-in view")
            // Start the sign-in flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            let user = result.user
            guard let idToken = user.idToken?.tokenString else {
                print("AuthViewModel: ID token missing from Google sign-in result")
                throw NSError(domain: "com.cheemhang.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID token missing"])
            }
            
            print("AuthViewModel: Got Google credentials, authenticating with Firebase")
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            try await Auth.auth().signIn(with: credential)
            print("AuthViewModel: Successfully signed in with Firebase")
            
            // Get user's calendar access token
            // This is where we would set up Google Calendar API if needed
            let scopes = ["https://www.googleapis.com/auth/calendar"]
            try await user.addScopes(scopes, presenting: rootViewController)
            
            // Now we should have calendar access
            // Store token in UserDefaults or another persistent storage
            UserDefaults.standard.set(user.accessToken.tokenString, forKey: "calendarAccessToken")
            print("AuthViewModel: Calendar access token stored")
            
        } catch {
            print("AuthViewModel: Error signing in with Google: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func signOut() {
        print("AuthViewModel: Signing out")
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            print("AuthViewModel: Successfully signed out")
        } catch {
            print("AuthViewModel: Error signing out: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    deinit {
        // Remove listener when viewmodel is deallocated
        if let authStateListener = authStateListener {
            Auth.auth().removeStateDidChangeListener(authStateListener)
        }
    }
} 