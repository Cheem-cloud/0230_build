import SwiftUI

// MARK: - Color Extensions
extension Color {
    // Hunter green and shades
    static let hunterGreen = Color(red: 53/255, green: 94/255, blue: 59/255) // Main hunter green
    static let hunterGreenLight = Color(red: 85/255, green: 126/255, blue: 91/255) // Lighter shade
    static let hunterGreenDark = Color(red: 35/255, green: 70/255, blue: 40/255) // Darker shade
    static let hunterGreenPale = Color(red: 209/255, green: 226/255, blue: 211/255) // Very light shade
    
    // Accent colors to complement the hunter green
    static let goldAccent = Color(red: 212/255, green: 175/255, blue: 55/255)
    static let creamAccent = Color(red: 245/255, green: 240/255, blue: 225/255)
}

// Theme-related view modifiers
extension View {
    // Apply standard styling to a primary button
    func primaryButtonStyle() -> some View {
        self
            .padding()
            .background(Color.hunterGreenLight)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
    
    // Apply standard styling to a secondary button
    func secondaryButtonStyle() -> some View {
        self
            .padding()
            .background(Color.hunterGreenPale)
            .foregroundColor(Color.hunterGreen)
            .cornerRadius(10)
    }
    
    // Apply standard styling to a card
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.hunterGreenDark)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
} 