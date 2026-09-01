//
//  AppleSpeechTranscriptionService.swift
//  suno
//

import Foundation
import Speech
import AVFoundation

class AppleSpeechTranscriptionService: TranscriptionService {
    private var activeRecognizers: [UUID: SFSpeechRecognizer] = [:]
    private var activeTasks: [UUID: SFSpeechRecognitionTask] = [:]
    
    // MARK: - Availability
    
    func checkAvailability() async -> Bool {
        return SFSpeechRecognizer.authorizationStatus() != .restricted
    }
    
    // MARK: - Permission
    
    func requestPermission() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    continuation.resume(returning: true)
                case .denied, .restricted:
                    continuation.resume(throwing: TranscriptionError.permissionDenied)
                case .notDetermined:
                    continuation.resume(returning: false)
                @unknown default:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Transcription
    
    func transcribe(
        recording: Recording,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> Transcript {
        print("🎙️ Starting transcription for: \(recording.fileName)")
        
        // Validate file exists
        guard FileManager.default.fileExists(atPath: recording.fileURL.path) else {
            throw TranscriptionError.audioFileNotFound
        }
        
        // Check file size
        let fileSize = try? FileManager.default.attributesOfItem(atPath: recording.fileURL.path)[.size] as? Int64
        if fileSize == 0 {
            throw TranscriptionError.emptyRecording
        }
        
        // Create recognizer
        guard let recognizer = SFSpeechRecognizer() else {
            throw TranscriptionError.speechRecognitionUnavailable
        }
        
        guard recognizer.isAvailable else {
            throw TranscriptionError.speechRecognitionUnavailable
        }
        
        // Store recognizer
        activeRecognizers[recording.id] = recognizer
        
        // Create request
        let request = SFSpeechURLRecognitionRequest(url: recording.fileURL)
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        
        // If available, use on-device recognition
        if #available(macOS 13.0, *) {
            request.requiresOnDeviceRecognition = false  // Allow server if needed
        }
        
        var transcript = Transcript(
            recordingID: recording.id,
            status: .transcribing
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    print("❌ Transcription error: \(error.localizedDescription)")
                    
                    // Check if cancelled
                    if (error as NSError).code == 1110 {
                        continuation.resume(throwing: TranscriptionError.cancelled)
                    } else {
                        continuation.resume(throwing: TranscriptionError.transcriptionFailed(error.localizedDescription))
                    }
                    return
                }
                
                guard let result = result else { return }
                
                // Update progress
                if result.isFinal {
                    progressHandler(1.0)
                } else {
                    // Estimate progress based on best transcription length
                    let estimatedProgress = min(0.9, Double(result.bestTranscription.formattedString.count) / 1000.0)
                    progressHandler(estimatedProgress)
                }
                
                if result.isFinal {
                    print("✅ Transcription complete!")
                    
                    // Group segments into natural phrases
                    let segments = self.groupSegments(result.bestTranscription.segments)
                    
                    transcript.segments = segments
                    transcript.fullText = result.bestTranscription.formattedString
                    transcript.status = .completed
                    transcript.completedAt = Date()
                    transcript.progress = 1.0
                    
                    continuation.resume(returning: transcript)
                }
            }
            
            // Store task for cancellation
            self.activeTasks[recording.id] = task
        }
    }
    
    // MARK: - Cancellation
    
    func cancelTranscription(for recordingID: UUID) {
        print("🛑 Cancelling transcription for: \(recordingID)")
        activeTasks[recordingID]?.cancel()
        activeTasks.removeValue(forKey: recordingID)
        activeRecognizers.removeValue(forKey: recordingID)
    }
    
    // MARK: - Segment Grouping
    
    /// Groups individual word segments into natural phrases based on pauses and punctuation
    private func groupSegments(_ segments: [SFTranscriptionSegment]) -> [TranscriptSegment] {
        guard !segments.isEmpty else { return [] }
        
        var groupedSegments: [TranscriptSegment] = []
        var currentText = ""
        var currentStartTime: TimeInterval = segments[0].timestamp
        var currentConfidences: [Float] = []
        var lastEndTime: TimeInterval = segments[0].timestamp
        
        for (index, segment) in segments.enumerated() {
            let word = segment.substring
            let isLastSegment = index == segments.count - 1
            
            // Add word to current phrase
            if currentText.isEmpty {
                currentText = word
                currentStartTime = segment.timestamp
            } else {
                currentText += " " + word
            }
            
            currentConfidences.append(segment.confidence)
            lastEndTime = segment.timestamp + segment.duration
            
            // Determine if we should end this phrase
            let shouldEndPhrase = isLastSegment || 
                                  shouldBreakAtSegment(segment, nextSegment: segments[safe: index + 1])
            
            if shouldEndPhrase {
                // Calculate average confidence
                let avgConfidence = currentConfidences.reduce(0, +) / Float(currentConfidences.count)
                
                // Create grouped segment
                let groupedSegment = TranscriptSegment(
                    text: currentText,
                    startTime: currentStartTime,
                    duration: lastEndTime - currentStartTime,
                    confidence: avgConfidence
                )
                
                groupedSegments.append(groupedSegment)
                
                // Reset for next phrase
                currentText = ""
                currentConfidences = []
            }
        }
        
        return groupedSegments
    }
    
    /// Determines if there should be a break between segments
    private func shouldBreakAtSegment(_ segment: SFTranscriptionSegment, nextSegment: SFTranscriptionSegment?) -> Bool {
        let word = segment.substring
        
        // Break on sentence-ending punctuation
        if word.hasSuffix(".") || word.hasSuffix("?") || word.hasSuffix("!") {
            return true
        }
        
        // Break on commas for longer pauses
        if word.hasSuffix(",") {
            // Only break if there's a significant pause after the comma
            if let next = nextSegment {
                let pauseDuration = next.timestamp - (segment.timestamp + segment.duration)
                if pauseDuration > 0.5 { // 500ms pause
                    return true
                }
            }
        }
        
        // Break on long pauses (indicating natural speech breaks)
        if let next = nextSegment {
            let pauseDuration = next.timestamp - (segment.timestamp + segment.duration)
            if pauseDuration > 1.0 { // 1 second pause
                return true
            }
        }
        
        // Break after approximately 10-15 words (to keep segments readable)
        // This is a rough heuristic based on typical sentence length
        return false
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
