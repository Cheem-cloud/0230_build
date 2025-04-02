import SwiftUI

struct HangoutCard: View {
    let hangout: Hangout
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "person.2.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 15, height: 15)
                .foregroundColor(.mutedGold)
            Text("\(hangout.attendeesCount)/\(hangout.maxAttendees)")
                .font(.caption)
                .foregroundColor(.charcoal)
        }
        .frame(height: 175)
        .cardStyle()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        .onTapGesture {
            onTap()
        }
    }
}

struct HangoutCard_Previews: PreviewProvider {
    static var previews: some View {
        HangoutCard(hangout: Hangout(attendeesCount: 5, maxAttendees: 10), onTap: {})
    }
} 