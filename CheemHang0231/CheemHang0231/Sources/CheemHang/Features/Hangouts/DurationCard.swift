import SwiftUI

struct DurationCard: View {
    let duration: Duration
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: durationIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .deepRed)
                
                Text(duration.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            
            Text(duration.description)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                .lineLimit(2)
        }
        .padding()
        .background(isSelected ? Color.deepRed : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: isSelected ? Color.deepRed.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
    
    private var durationIcon: String {
        switch duration {
        case .short:
            return "clock.fill"
        case .medium:
            return "clock.fill"
        case .long:
            return "clock.badge.fill"
        case .extended:
            return "clock.badge.checkmark.fill"
        }
    }
} 