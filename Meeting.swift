//
//  Meeting.swift
//  suno
//

import Foundation

enum MeetingSource: String, Codable {
    case teams = "Microsoft Teams"
    case zoom = "Zoom"
    case meet = "Google Meet"
    case webex = "Webex"
    case calendar = "Calendar"
    case manual = "Manual"
}

struct Meeting: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let participants: [String]
    let location: String?
    let notes: String?
    let source: MeetingSource
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var participantCount: Int { participants.count }
    
    var participantsString: String {
        if participants.isEmpty { return "No participants" }
        if participants.count <= 3 { return participants.joined(separator: ", ") }
        return "\(participants.count) participants"
    }
    
    func contains(_ date: Date) -> Bool {
        date >= startDate && date <= endDate
    }
    
    var isHappening: Bool { contains(Date()) }
    
    func startsWithin(minutes: Int) -> Bool {
        let timeUntilStart = startDate.timeIntervalSince(Date())
        return timeUntilStart > 0 && timeUntilStart <= TimeInterval(minutes * 60)
    }
    
    func endedWithin(minutes: Int) -> Bool {
        let timeSinceEnd = Date().timeIntervalSince(endDate)
        return timeSinceEnd > 0 && timeSinceEnd <= TimeInterval(minutes * 60)
    }
    
    static var unscheduled: Meeting {
        Meeting(
            id: "unscheduled",
            title: "Unscheduled Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            participants: [],
            location: nil,
            notes: nil,
            source: .manual
        )
    }
    
    var isUnscheduled: Bool { id == "unscheduled" }
}
