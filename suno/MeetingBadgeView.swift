//
//  MeetingBadgeView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

struct MeetingBadgeView: View {
    let meeting: Meeting
    let compact: Bool
    
    init(meeting: Meeting, compact: Bool = false) {
        self.meeting = meeting
        self.compact = compact
    }
    
    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }
    
    private var compactView: some View {
        HStack(spacing: 6) {
            Image(systemName: meeting.isUnscheduled ? "calendar.badge.exclamationmark" : "calendar")
                .font(.caption)
                .foregroundStyle(meeting.isUnscheduled ? .orange : .blue)
            
            Text(meeting.title)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var fullView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and icon
            HStack(spacing: 8) {
                Image(systemName: meeting.isUnscheduled ? "calendar.badge.exclamationmark" : "calendar.badge.checkmark")
                    .foregroundStyle(meeting.isUnscheduled ? .orange : .green)
                
                Text(meeting.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
            }
            
            if !meeting.isUnscheduled {
                // Time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(meeting.formattedTime)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                
                // Participants
                if !meeting.participants.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2")
                            .font(.caption)
                        Text(meeting.participantsString)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Location
                if let location = meeting.location, !location.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "location")
                            .font(.caption)
                        Text(location)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(meeting.isUnscheduled ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview("Scheduled Meeting") {
    VStack(spacing: 16) {
        MeetingBadgeView(
            meeting: Meeting(
                id: "test",
                title: "Team Standup",
                startDate: Date(),
                endDate: Date().addingTimeInterval(1800),
                participants: ["Alice", "Bob", "Charlie"],
                location: "Conference Room A",
                notes: nil,
                source: .calendar
            ),
            compact: false
        )
        
        MeetingBadgeView(
            meeting: Meeting(
                id: "test",
                title: "Team Standup",
                startDate: Date(),
                endDate: Date().addingTimeInterval(1800),
                participants: ["Alice", "Bob", "Charlie"],
                location: "Conference Room A",
                notes: nil,
                source: .calendar
            ),
            compact: false
        )
    }
    .frame(width: 350)
    .padding()
}

#Preview("Unscheduled") {
    VStack(spacing: 16) {
        MeetingBadgeView(meeting: .unscheduled, compact: false)
        MeetingBadgeView(meeting: .unscheduled, compact: true)
    }
    .frame(width: 350)
    .padding()
}
