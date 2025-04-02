import SwiftUI

// MARK: - Color Extensions
extension Color {
    // Primary colors
    static let deepRed = Color(hex: "821d1d") // Base deep red
    static let white = Color.white // White
    
    // Darker shades for depth
    static let burgundy = Color(hex: "5f1515") // Dark burgundy for headers/accents
    static let charcoal = Color(hex: "333333") // Charcoal gray for text/backgrounds
    
    // Light shades for contrast
    static let softPink = Color(hex: "e8d9d9") // Subtle background/highlight
    static let lightGray = Color(hex: "f5f5f5") // Secondary light background
    
    // Accent colors
    static let mutedGold = Color(hex: "c49f48") // Highlights, call-to-action
    static let tealGreen = Color(hex: "197d7d") // Complementary accent
    
    // Initialize a Color from a hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Theme-related view modifiers
extension View {
    // Apply standard styling to a primary button
    func primaryButtonStyle() -> some View {
        self
            .padding()
            .background(Color.deepRed)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
    
    // Apply standard styling to a secondary button
    func secondaryButtonStyle() -> some View {
        self
            .padding()
            .background(Color.softPink)
            .foregroundColor(Color.burgundy)
            .cornerRadius(10)
    }
    
    // Apply standard styling to a card
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.charcoal.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Apply premium styling to a card
    func premiumCardStyle() -> some View {
        self
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.mutedGold, lineWidth: 1)
            )
            .cornerRadius(12)
            .shadow(color: Color.charcoal.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Apply floating pill style to navigation elements
    func floatingPillStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.deepRed)
                    .shadow(color: Color.charcoal.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal)
    }
} 