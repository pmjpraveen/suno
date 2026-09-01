//
//  AudioRecorderService.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import Foundation
import AVFoundation

@Observable
class AudioRecorderService: NSObject {
    // MARK: - Published State
    var recordingState: RecordingState = .idle
    var currentDuration: TimeInterval = 0
    var hasPermission: Bool = false
    var errorMessage: String?
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStartTime: Date?
    
    private var currentRecordingURL: URL?
    private var currentFormat: AudioFormat = .m4a
    
    override init() {
        super.init()
        checkPermission()
    }
    
    // MARK: - Permission Management
    
    func checkPermission() {
        #if os(macOS)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasPermission = true
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            hasPermission = false
        @unknown default:
            hasPermission = false
        }
        #endif
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if !granted {
                    self?.errorMessage = "Microphone permission is required to record audio."
                }
            }
        }
    }
    
    // MARK: - Recording Controls
    
    func startRecording(format: AudioFormat) async throws {
        guard hasPermission else {
            errorMessage = "Microphone permission not granted"
            throw RecordingError.permissionDenied
        }
        
        guard recordingState == .idle else {
            throw RecordingError.invalidState
        }
        
        currentFormat = format
        currentRecordingURL = RecordingStorageService.shared.createAudioFileURL(format: format)
        
        guard let url = currentRecordingURL else {
            throw RecordingError.fileCreationFailed
        }
        
        // Configure audio session
        try configureAudioSession()
        
        // Create audio recorder
        audioRecorder = try AVAudioRecorder(url: url, settings: format.audioSettings)
        audioRecorder?.delegate = self
        audioRecorder?.prepareToRecord()
        
        // Start recording
        guard audioRecorder?.record() == true else {
            throw RecordingError.recordingFailed
        }
        
        // Update state
        recordingState = .recording
        recordingStartTime = Date()
        currentDuration = 0
        pausedDuration = 0
        
        // Start timer
        startTimer()
        
        errorMessage = nil
    }
    
    func pauseRecording() {
        guard recordingState == .recording else { return }
        
        audioRecorder?.pause()
        pauseStartTime = Date()
        recordingState = .paused
        stopTimer()
    }
    
    func resumeRecording() {
        guard recordingState == .paused else { return }
        
        if let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        
        audioRecorder?.record()
        recordingState = .recording
        startTimer()
    }
    
    func stopRecording() async throws -> Recording? {
        guard recordingState == .recording || recordingState == .paused else {
            throw RecordingError.invalidState
        }
        
        stopTimer()
        audioRecorder?.stop()
        
        recordingState = .stopped
        
        // Calculate final duration
        let endTime = Date()
        guard let startTime = recordingStartTime else {
            throw RecordingError.recordingFailed
        }
        
        let totalDuration = endTime.timeIntervalSince(startTime) - pausedDuration
        
        // Get file URL and size
        guard let fileURL = currentRecordingURL else {
            throw RecordingError.fileCreationFailed
        }
        
        let fileSize = RecordingStorageService.shared.getFileSize(at: fileURL)
        
        // Create recording metadata
        let recording = Recording(
            fileName: fileURL.lastPathComponent,
            fileURL: fileURL,
            format: currentFormat,
            startTime: startTime,
            endTime: endTime,
            duration: totalDuration,
            fileSize: fileSize,
            calendarEventID: nil,
            meetingTitle: nil,
            meetingParticipants: nil
        )
        
        // Reset state
        resetRecordingState()
        
        return recording
    }
    
    func cancelRecording() throws {
        guard recordingState == .recording || recordingState == .paused else {
            throw RecordingError.invalidState
        }
        
        stopTimer()
        audioRecorder?.stop()
        
        // Delete the file
        if let url = currentRecordingURL {
            try? RecordingStorageService.shared.deleteAudioFile(at: url)
        }
        
        resetRecordingState()
    }
    
    // MARK: - Private Helpers
    
    private func configureAudioSession() throws {
        #if os(macOS)
        // macOS doesn't require audio session configuration like iOS
        // But we can set up the audio engine if needed
        #endif
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateDuration() {
        guard let startTime = recordingStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime) - pausedDuration
        
        // Adjust for paused time if currently paused
        if recordingState == .paused, let pauseStart = pauseStartTime {
            let currentPausedTime = Date().timeIntervalSince(pauseStart)
            currentDuration = elapsed - currentPausedTime
        } else {
            currentDuration = elapsed
        }
    }
    
    private func resetRecordingState() {
        recordingState = .idle
        currentDuration = 0
        pausedDuration = 0
        recordingStartTime = nil
        pauseStartTime = nil
        currentRecordingURL = nil
        audioRecorder = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Recording failed to complete successfully"
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        errorMessage = error?.localizedDescription ?? "An encoding error occurred"
        recordingState = .idle
        stopTimer()
    }
}

// MARK: - Recording Errors

enum RecordingError: LocalizedError {
    case permissionDenied
    case invalidState
    case fileCreationFailed
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record audio."
        case .invalidState:
            return "Cannot perform this action in the current recording state."
        case .fileCreationFailed:
            return "Failed to create recording file."
        case .recordingFailed:
            return "Recording failed to start or complete."
        }
    }
}
