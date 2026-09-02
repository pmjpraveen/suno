//
//  AIAnalysisService.swift
//  suno
//

import Foundation

/// Protocol for AI-powered meeting analysis services
protocol AIAnalysisService {
    /// Check if the service is available on this system
    func checkAvailability() async -> Bool
    
    /// Analyze a meeting transcript and generate insights
    /// - Parameters:
    ///   - transcript: The complete transcript to analyze
    ///   - meeting: Optional meeting context for better analysis
    /// - Returns: Structured analysis response
    /// - Throws: AIAnalysisError if analysis fails
    func analyzeTranscript(
        _ transcript: Transcript,
        meeting: Meeting?
    ) async throws -> AIAnalysisResponse
}

/// Errors that can occur during AI analysis
enum AIAnalysisError: LocalizedError {
    case serviceUnavailable
    case invalidTranscript
    case emptyTranscript
    case analysisTimeout
    case networkError(String)
    case decodingError(String)
    case apiError(String)
    case cancelled
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI analysis service is not available on this system"
        case .invalidTranscript:
            return "The transcript is invalid or corrupted"
        case .emptyTranscript:
            return "The transcript is empty or too short to analyze"
        case .analysisTimeout:
            return "Analysis timed out. Please try again."
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError(let message):
            return "Failed to decode analysis response: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .cancelled:
            return "Analysis was cancelled"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
