import SwiftUI

struct HangoutTypeCard: View {
    let type: HangoutType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .deepRed)
                
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            
            Text(type.description)
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
} 