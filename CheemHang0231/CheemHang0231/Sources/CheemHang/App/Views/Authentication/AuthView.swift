import SwiftUI

struct AuthView: View {
    @StateObject var viewModel = AuthViewModel()
    @State private var isSignUp = false
    
    var body: some View {
        ZStack {
            // Create a gradient background using our new colors
            LinearGradient(
                gradient: Gradient(colors: [Color.deepRed, Color.burgundy]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Logo and App Title
                VStack(spacing: 8) {
                    Image("cheem-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(radius: 5)
                    
                    Text("Unhinged")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Dating without filters")
                        .font(.subheadline)
                        .foregroundColor(.softPink)
                }
                .padding(.bottom, 40)
                
                // Authentication Form
                VStack(spacing: 15) {
                    if isSignUp {
                        TextField("Name", text: $viewModel.name)
                            .textFieldStyle(AuthTextFieldStyle())
                    }
                    
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(AuthTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(AuthTextFieldStyle())
                    
                    if isSignUp {
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textFieldStyle(AuthTextFieldStyle())
                    }
                }
                .padding(.horizontal, 30)
                
                // Error message
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                }
                
                // Sign In / Sign Up Button
                Button(action: {
                    if isSignUp {
                        viewModel.signUp()
                    } else {
                        viewModel.signIn()
                    }
                }) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.headline)
                        .foregroundColor(.deepRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .disabled(viewModel.isLoading)
                .opacity(viewModel.isLoading ? 0.6 : 1)
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // Toggle between Sign In and Sign Up
                Button(action: {
                    isSignUp.toggle()
                    viewModel.errorMessage = ""
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundColor(.softPink)
                        .padding(.top, 10)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding()
                }
                
                Spacer()
            }
        }
    }
}

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(10)
            .foregroundColor(.charcoal)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.softPink, lineWidth: 1)
            )
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
} 