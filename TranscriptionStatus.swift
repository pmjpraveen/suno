//
//  TranscriptionStatus.swift
//  suno
//

import Foundation

enum TranscriptionStatus: String, Codable {
    case pending = "pending"
    case transcribing = "transcribing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    var displayText: String {
        switch self {
        case .pending:
            return "Waiting to transcribe"
        case .transcribing:
            return "Transcribing..."
        case .completed:
            return "Transcribed"
        case .failed:
            return "Transcription failed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .transcribing:
            return "waveform.circle"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .cancelled:
            return "xmark.circle"
        }
    }
}
