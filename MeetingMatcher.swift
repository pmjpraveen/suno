//
//  MeetingMatcher.swift
//  suno
//

import Foundation

class MeetingMatcher {
    static func findBestMatch(at time: Date, from meetings: [Meeting]) -> Meeting? {
        let scheduled = meetings.filter { !$0.isUnscheduled }
        guard !scheduled.isEmpty else { return nil }
        
        // Happening now
        let happening = scheduled.filter { $0.contains(time) }
        if !happening.isEmpty {
            return happening.sorted { $0.startDate > $1.startDate }.first
        }
        
        // Starting soon
        let soon = scheduled.filter { $0.startsWithin(minutes: 5) }
        if !soon.isEmpty {
            return soon.min(by: { $0.startDate < $1.startDate })
        }
        
        // Just ended
        let ended = scheduled.filter { $0.endedWithin(minutes: 5) }
        return ended.max(by: { $0.endDate < $1.endDate })
    }
    
    static func getMeetingsForSelection(from meetings: [Meeting], includeUnscheduled: Bool = true) -> [Meeting] {
        var result = meetings.filter { !$0.isUnscheduled }.sorted { $0.startDate < $1.startDate }
        if includeUnscheduled { result.append(.unscheduled) }
        return result
    }
}
