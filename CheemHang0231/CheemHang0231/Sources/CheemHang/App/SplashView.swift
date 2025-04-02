import SwiftUI

struct SplashView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        VStack {
            VStack {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                Text("Unhinged")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Connect through personas")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.deepRed)
        .edgesIgnoringSafeArea(.all)
    }
} 