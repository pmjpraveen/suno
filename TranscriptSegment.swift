//
//  TranscriptSegment.swift
//  suno
//

import Foundation

/// Which captured audio a segment was transcribed from, when the recording has both.
enum AudioSource: String, Codable {
    case me
    case meeting
}

struct TranscriptSegment: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let startTime: TimeInterval  // Seconds from recording start
    let duration: TimeInterval
    var confidence: Float?  // 0.0 to 1.0
    var source: AudioSource?  // nil when there's only one captured audio track

    init(
        id: UUID = UUID(),
        text: String,
        startTime: TimeInterval,
        duration: TimeInterval,
        confidence: Float? = nil,
        source: AudioSource? = nil
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.duration = duration
        self.confidence = confidence
        self.source = source
    }
    
    // MARK: - Computed Properties
    
    var formattedTime: String {
        let hours = Int(startTime) / 3600
        let minutes = Int(startTime) / 60 % 60
        let seconds = Int(startTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var endTime: TimeInterval {
        startTime + duration
    }
}
