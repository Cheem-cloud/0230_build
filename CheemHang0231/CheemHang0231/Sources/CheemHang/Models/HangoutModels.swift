import Foundation

// MARK: - Hangout Types
enum HangoutType: String, CaseIterable, Identifiable, Codable {
    case coffee = "Coffee"
    case meal = "Meal"
    case activity = "Activity"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .meal: return "fork.knife"
        case .activity: return "figure.hiking"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .coffee: return "A quick coffee or tea meetup"
        case .meal: return "Lunch, dinner, or brunch"
        case .activity: return "Something fun to do together"
        case .other: return "Something else entirely"
        }
    }
}

// MARK: - Duration Options
enum Duration: TimeInterval, CaseIterable, Identifiable, Codable {
    case thirtyMinutes = 1800 // 30 minutes in seconds
    case oneHour = 3600      // 60 minutes in seconds
    case ninetyMinutes = 5400 // 90 minutes in seconds
    case twoHours = 7200     // 120 minutes in seconds
    
    var id: TimeInterval { self.rawValue }
    
    var displayName: String {
        switch self {
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .ninetyMinutes: return "1.5 hours"
        case .twoHours: return "2 hours"
        }
    }
}

// MARK: - Time Slots
struct TimeSlot: Identifiable, Equatable {
    let id = UUID()
    let start: Date
    let end: Date
    
    var dateTimeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: start)
    }
    
    var timeRangeString: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return "\(timeFormatter.string(from: start)) - \(timeFormatter.string(from: end))"
    }
    
    var dayString: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, MMM d"
        return dayFormatter.string(from: start)
    }
} 