//
//  Recording.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import Foundation

struct Recording: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let fileURL: URL
    let format: AudioFormat
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var fileSize: Int64
    
    // Calendar integration
    var calendarEventID: String?
    var meetingTitle: String?
    var meetingParticipants: [String]?
    
    // Future AI integration
    var transcription: String?
    var summary: String?
    
    init(
        id: UUID = UUID(),
        fileName: String,
        fileURL: URL,
        format: AudioFormat,
        startTime: Date,
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        fileSize: Int64 = 0,
        calendarEventID: String? = nil,
        meetingTitle: String? = nil,
        meetingParticipants: [String]? = nil,
        transcription: String? = nil,
        summary: String? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileURL = fileURL
        self.format = format
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.fileSize = fileSize
        self.calendarEventID = calendarEventID
        self.meetingTitle = meetingTitle
        self.meetingParticipants = meetingParticipants
        self.transcription = transcription
        self.summary = summary
    }
    
    // MARK: - Computed Properties
    
    var hasMeeting: Bool {
        calendarEventID != nil && calendarEventID != "unscheduled"
    }
    
    var isUnscheduledMeeting: Bool {
        calendarEventID == "unscheduled"
    }
    
    var displayTitle: String {
        meetingTitle ?? "Recording"
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}
