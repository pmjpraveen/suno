//
//  AppleSpeechTranscriptionService.swift
//  suno
//

import Foundation
import Speech
import AVFoundation

class AppleSpeechTranscriptionService {
    private var activeRecognizers: [String: SFSpeechRecognizer] = [:]
    private var activeTasks: [String: SFSpeechRecognitionTask] = [:]

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

        let hasSystemAudio = recording.systemAudioFileURL.map {
            FileManager.default.fileExists(atPath: $0.path)
        } ?? false

        var transcript = Transcript(
            recordingID: recording.id,
            status: .transcribing,
            requestedLanguage: language
        )

        guard hasSystemAudio, let systemAudioURL = recording.systemAudioFileURL else {
            // Mic-only recording — unchanged single-file path.
            let result = try await recognize(
                fileURL: recording.fileURL,
                language: language,
                taskKey: "\(recording.id)-mic",
                progressHandler: progressHandler
            )
            transcript.segments = result.segments
            transcript.fullText = result.fullText
            transcript.status = .completed
            transcript.completedAt = Date()
            transcript.progress = 1.0
            transcript.language = language
            return transcript
        }

        // Recording has a separately-captured system audio track (the other meeting
        // participants). Transcribe each track on its own — mixing two speech signals
        // into one recognizer call tends to make recognition worse, not better — then
        // merge the results back into one chronological transcript.
        let mic = try await recognize(
            fileURL: recording.fileURL,
            language: language,
            taskKey: "\(recording.id)-mic",
            progressHandler: { progressHandler($0 * 0.5) }
        )
        var segments = mic.segments.map { tagged($0, as: .me) }

        do {
            let meeting = try await recognize(
                fileURL: systemAudioURL,
                language: language,
                taskKey: "\(recording.id)-meeting",
                progressHandler: { progressHandler(0.5 + $0 * 0.5) }
            )
            segments += meeting.segments.map { tagged($0, as: .meeting) }
        } catch {
            // The mic track is the primary source; a failure transcribing the system
            // audio track (e.g. it was too short or silent) shouldn't fail the whole thing.
            print("⚠️ System audio transcription skipped: \(error.localizedDescription)")
        }

        segments.sort { $0.startTime < $1.startTime }

        transcript.segments = segments
        transcript.fullText = segments.map(\.text).joined(separator: " ")
        transcript.status = .completed
        transcript.completedAt = Date()
        transcript.progress = 1.0
        transcript.language = language
        return transcript
    }

    private func tagged(_ segment: TranscriptSegment, as source: AudioSource) -> TranscriptSegment {
        var segment = segment
        segment.source = source
        return segment
    }

    /// Runs speech recognition on one audio file and returns its grouped segments.
    private func recognize(
        fileURL: URL,
        language: suno.Language,
        taskKey: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> (segments: [TranscriptSegment], fullText: String) {
        print("📁 File path: \(fileURL.path)")

        // Validate file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("❌ Audio file not found at path: \(fileURL.path)")
            throw TranscriptionError.audioFileNotFound
        }

        // Check file size
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes?[.size] as? Int64 ?? 0
        print("📊 File size: \(fileSize) bytes")

        if fileSize == 0 {
            print("❌ Empty recording file")
            throw TranscriptionError.emptyRecording
        }

        // Validate audio file can be opened
        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
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

        // Create recognizer with specified language. SFSpeechRecognizer cannot auto-detect
        // the spoken language from audio — "Auto" just uses the Mac's system language, so
        // callers should pick a specific language for anything not in that language.
        let recognizer: SFSpeechRecognizer?
        if let locale = language.locale {
            recognizer = SFSpeechRecognizer(locale: locale)
            print("🌍 Using language: \(language.displayName) (\(locale.identifier))")
        } else {
            recognizer = SFSpeechRecognizer()
            print("🌍 Using system locale (Auto-Detect)")
        }

        guard let recognizer = recognizer else {
            print("❌ Speech recognizer unavailable")
            throw TranscriptionError.speechRecognitionUnavailable
        }

        guard recognizer.isAvailable else {
            print("❌ Language not supported: \(language.displayName)")
            throw TranscriptionError.languageNotSupported(language.displayName)
        }

        activeRecognizers[taskKey] = recognizer

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = true
        request.taskHint = .unspecified  // conversational meeting audio, not single-speaker dictation
        request.requiresOnDeviceRecognition = false  // allow server fallback for better accuracy
        print("🚀 Starting recognition task...")

        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false

            let task = recognizer.recognitionTask(with: request) { result, error in
                guard !hasResumed else { return }

                if let error = error {
                    print("❌ Transcription error: \(error.localizedDescription)")

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

                if result.isFinal {
                    progressHandler(1.0)
                } else {
                    let estimatedProgress = min(0.9, Double(result.bestTranscription.formattedString.count) / 1000.0)
                    progressHandler(estimatedProgress)
                }

                if result.isFinal {
                    print("✅ Transcription complete!")
                    print("📝 Transcribed text length: \(result.bestTranscription.formattedString.count) characters")
                    print("📊 Segment count: \(result.bestTranscription.segments.count)")

                    let segments = self.groupSegments(result.bestTranscription.segments)

                    hasResumed = true
                    continuation.resume(returning: (segments, result.bestTranscription.formattedString))

                    self.activeTasks.removeValue(forKey: taskKey)
                    self.activeRecognizers.removeValue(forKey: taskKey)
                }
            }

            self.activeTasks[taskKey] = task

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
        for taskKey in ["\(recordingID)-mic", "\(recordingID)-meeting"] {
            activeTasks[taskKey]?.cancel()
            activeTasks.removeValue(forKey: taskKey)
            activeRecognizers.removeValue(forKey: taskKey)
        }
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
