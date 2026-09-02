//
//  Transcript.swift
//  suno
//

import Foundation

struct Transcript: Identifiable, Codable {
    let id: UUID
    let recordingID: UUID
    var status: TranscriptionStatus
    var segments: [TranscriptSegment]
    var fullText: String
    let createdAt: Date
    var completedAt: Date?
    var errorMessage: String?
    var progress: Double  // 0.0 to 1.0
    var language: Language?  // Detected or specified language
    var requestedLanguage: Language  // Language requested for transcription
    
    init(
        id: UUID = UUID(),
        recordingID: UUID,
        status: TranscriptionStatus = .pending,
        segments: [TranscriptSegment] = [],
        fullText: String = "",
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        errorMessage: String? = nil,
        progress: Double = 0.0,
        language: Language? = nil,
        requestedLanguage: Language = .auto
    ) {
        self.id = id
        self.recordingID = recordingID
        self.status = status
        self.segments = segments
        self.fullText = fullText
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.errorMessage = errorMessage
        self.progress = progress
        self.language = language
        self.requestedLanguage = requestedLanguage
    }
    
    // MARK: - Computed Properties
    
    var isComplete: Bool {
        status == .completed
    }
    
    var isInProgress: Bool {
        status == .transcribing
    }
    
    var hasFailed: Bool {
        status == .failed
    }
    
    var canRetry: Bool {
        status == .failed || status == .cancelled
    }
    
    var segmentCount: Int {
        segments.count
    }
    
    var wordCount: Int {
        fullText.split(separator: " ").count
    }
}
