//
//  AppleSpeechTranscriptionService.swift
//  suno
//

import Foundation
import Speech
import AVFoundation

class AppleSpeechTranscriptionService {
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
        language: suno.Language = .auto,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> Transcript {
        print("🎙️ Starting transcription for: \(recording.fileName)")
        print("📁 File path: \(recording.fileURL.path)")
        
        // Validate file exists
        guard FileManager.default.fileExists(atPath: recording.fileURL.path) else {
            print("❌ Audio file not found at path: \(recording.fileURL.path)")
            throw TranscriptionError.audioFileNotFound
        }
        
        // Check file size
        let attributes = try? FileManager.default.attributesOfItem(atPath: recording.fileURL.path)
        let fileSize = attributes?[.size] as? Int64 ?? 0
        print("📊 File size: \(fileSize) bytes")
        
        if fileSize == 0 {
            print("❌ Empty recording file")
            throw TranscriptionError.emptyRecording
        }
        
        // Validate audio file can be opened
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: recording.fileURL)
            let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
            print("🎵 Audio duration: \(String(format: "%.2f", duration)) seconds")
            print("🎵 Sample rate: \(audioFile.fileFormat.sampleRate) Hz")
            print("🎵 Channels: \(audioFile.fileFormat.channelCount)")
            
            if duration < 0.5 {
                print("❌ Recording too short to transcribe")
                throw TranscriptionError.emptyRecording
            }
        } catch {
            print("❌ Could not open audio file: \(error.localizedDescription)")
            throw TranscriptionError.transcriptionFailed("Invalid audio file: \(error.localizedDescription)")
        }
        
        // Create recognizer with specified language
        let recognizer: SFSpeechRecognizer?
        if language == .auto, let locale = language.locale {
            // Auto-detect: use default system locale
            recognizer = SFSpeechRecognizer()
            print("🌍 Using auto-detection with system locale")
        } else if let locale = language.locale {
            // Use specified language locale
            recognizer = SFSpeechRecognizer(locale: locale)
            print("🌍 Using language: \(language.displayName) (\(locale.identifier))")
        } else {
            // Fallback to default recognizer for auto-detect
            recognizer = SFSpeechRecognizer()
            print("🌍 Using default system recognizer")
        }
        
        guard let recognizer = recognizer else {
            print("❌ Speech recognizer unavailable")
            throw TranscriptionError.speechRecognitionUnavailable
        }
        
        guard recognizer.isAvailable else {
            print("❌ Language not supported: \(language.displayName)")
            throw TranscriptionError.languageNotSupported(language.displayName)
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
            print("🖥️ On-device recognition: fallback to server if needed")
        }
        
        var transcript = Transcript(
            recordingID: recording.id,
            status: TranscriptionStatus.transcribing,
            requestedLanguage: language
        )
        
        print("🚀 Starting recognition task...")
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            let task = recognizer.recognitionTask(with: request) { result, error in
                // Prevent multiple resumes
                guard !hasResumed else { return }
                
                if let error = error {
                    print("❌ Transcription error: \(error.localizedDescription)")
                    
                    // Check if cancelled
                    if (error as NSError).code == 1110 {
                        hasResumed = true
                        continuation.resume(throwing: TranscriptionError.cancelled)
                    } else {
                        hasResumed = true
                        continuation.resume(throwing: TranscriptionError.transcriptionFailed(error.localizedDescription))
                    }
                    return
                }
                
                guard let result = result else { return }
                
                // Update progress
                if result.isFinal {
                    progressHandler(1.0)
                } else {
                    // Estimate progress based on transcription length and recording duration
                    let estimatedProgress = min(0.9, Double(result.bestTranscription.formattedString.count) / 1000.0)
                    progressHandler(estimatedProgress)
                }
                
                // Only complete when we have final results
                if result.isFinal {
                    print("✅ Transcription complete!")
                    print("📝 Transcribed text length: \(result.bestTranscription.formattedString.count) characters")
                    print("📊 Segment count: \(result.bestTranscription.segments.count)")
                    
                    // Group segments into natural phrases
                    let segments = self.groupSegments(result.bestTranscription.segments)
                    
                    transcript.segments = segments
                    transcript.fullText = result.bestTranscription.formattedString
                    transcript.status = .completed
                    transcript.completedAt = Date()
                    transcript.progress = 1.0
                    
                    hasResumed = true
                    continuation.resume(returning: transcript)
                    
                    // Clean up
                    self.activeTasks.removeValue(forKey: recording.id)
                    self.activeRecognizers.removeValue(forKey: recording.id)
                }
            }
            
            // Store task for cancellation
            self.activeTasks[recording.id] = task
            
            // Add timeout for very long recordings (2 hours)
            Task {
                try? await Task.sleep(nanoseconds: 7_200_000_000_000) // 2 hours
                if !hasResumed {
                    print("⏱️ Transcription timeout reached")
                    task.cancel()
                }
            }
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
