//
//  TranscriptionService.swift
//  suno
//

import Foundation

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
