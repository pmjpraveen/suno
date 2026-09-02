//
//  AnalysisStatus.swift
//  suno
//

import Foundation

enum AnalysisStatus: String, Codable {
    case pending = "pending"
    case analyzing = "analyzing"
    case completed = "completed"
    case failed = "failed"
    
    var displayText: String {
        switch self {
        case .pending:
            return "Not analyzed"
        case .analyzing:
            return "Analyzing..."
        case .completed:
            return "Analysis complete"
        case .failed:
            return "Analysis failed"
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "brain"
        case .analyzing:
            return "brain.filled.head.profile"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
}
