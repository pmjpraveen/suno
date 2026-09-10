//
//  AIAnalysisService.swift
//  suno
//

import Foundation

/// Errors that can occur during AI analysis
enum AIAnalysisError: LocalizedError {
    case serviceUnavailable
    case invalidTranscript
    case emptyTranscript
    case apiError(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI analysis service is not available on this system"
        case .invalidTranscript:
            return "The transcript is invalid or corrupted"
        case .emptyTranscript:
            return "The transcript is empty or too short to analyze"
        case .apiError(let message):
            return "API error: \(message)"
        case .cancelled:
            return "Analysis was cancelled"
        }
    }
}
