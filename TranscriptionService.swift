//
//  TranscriptionService.swift
//  suno
//

import Foundation

protocol TranscriptionService {
    /// Check if speech recognition is available
    func checkAvailability() async -> Bool
    
    /// Request speech recognition permission
    func requestPermission() async throws -> Bool
    
    /// Transcribe an audio file
    /// - Parameters:
    ///   - recording: The recording to transcribe
    ///   - language: Language for transcription (default: .auto for auto-detection)
    ///   - progressHandler: Called with progress updates (0.0 to 1.0)
    /// - Returns: Completed transcript with segments
    func transcribe(
        recording: Recording,
        language: Language,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> Transcript
    
    /// Cancel ongoing transcription
    func cancelTranscription(for recordingID: UUID)
}

// MARK: - Transcription Errors

enum TranscriptionError: LocalizedError {
    case speechRecognitionUnavailable
    case permissionDenied
    case audioFileNotFound
    case unsupportedAudioFormat
    case emptyRecording
    case networkRequired
    case languageNotSupported(String)
    case transcriptionFailed(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .speechRecognitionUnavailable:
            return "Speech recognition is not available on this device."
        case .permissionDenied:
            return "Speech recognition permission was denied. Enable it in System Settings."
        case .audioFileNotFound:
            return "The audio file could not be found."
        case .unsupportedAudioFormat:
            return "This audio format is not supported for transcription."
        case .emptyRecording:
            return "The recording is empty or too short to transcribe."
        case .networkRequired:
            return "Network connection required for transcription."
        case .languageNotSupported(let language):
            return "Language '\(language)' is not supported for transcription. Try auto-detection or select a different language."
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .cancelled:
            return "Transcription was cancelled."
        }
    }
}
