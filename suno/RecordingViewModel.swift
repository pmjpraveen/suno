//
//  RecordingViewModel.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import Foundation
import AVFoundation
import AppKit
import Combine

class RecordingViewModel: ObservableObject {
    // MARK: - Services
    private let audioService = AudioRecorderService()
    private let storageService = RecordingStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    @Published var recordings: [Recording] = []
    @Published var selectedFormat: AudioFormat = .m4a
    @Published var errorMessage: String?
    @Published var isShowingError = false
    
    // Passthrough from audio service
    var recordingState: RecordingState {
        audioService.recordingState
    }
    
    var currentDuration: TimeInterval {
        audioService.currentDuration
    }
    
    var hasPermission: Bool {
        audioService.hasPermission
    }
    
    // MARK: - Computed Properties
    
    var formattedDuration: String {
        formatDuration(currentDuration)
    }
    
    var canStartRecording: Bool {
        recordingState == .idle && hasPermission
    }
    
    var canPauseRecording: Bool {
        recordingState == .recording
    }
    
    var canResumeRecording: Bool {
        recordingState == .paused
    }
    
    var canStopRecording: Bool {
        recordingState == .recording || recordingState == .paused
    }
    
    // MARK: - Initialization
    
    init() {
        loadRecordings()
        loadSelectedFormat()
    }
    
    // MARK: - Recording Actions
    
    func startRecording() {
        Task {
            do {
                try await audioService.startRecording(format: selectedFormat)
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func pauseRecording() {
        audioService.pauseRecording()
    }
    
    func resumeRecording() {
        audioService.resumeRecording()
    }
    
    func stopRecording() {
        Task {
            do {
                if let recording = try await audioService.stopRecording() {
                    await MainActor.run {
                        saveRecording(recording)
                    }
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    func cancelRecording() {
        do {
            try audioService.cancelRecording()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Recording Management
    
    private func saveRecording(_ recording: Recording) {
        do {
            try storageService.addRecording(recording, to: &recordings)
            // Sort recordings by start time (newest first)
            recordings.sort { $0.startTime > $1.startTime }
        } catch {
            handleError(error)
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        do {
            try storageService.deleteRecording(recording, from: &recordings)
        } catch {
            handleError(error)
        }
    }
    
    func loadRecordings() {
        do {
            recordings = try storageService.loadRecordings()
            // Sort recordings by start time (newest first)
            recordings.sort { $0.startTime > $1.startTime }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Format Management
    
    func selectFormat(_ format: AudioFormat) {
        selectedFormat = format
        saveSelectedFormat()
    }
    
    private func saveSelectedFormat() {
        UserDefaults.standard.set(selectedFormat.rawValue, forKey: "selectedAudioFormat")
    }
    
    private func loadSelectedFormat() {
        if let formatString = UserDefaults.standard.string(forKey: "selectedAudioFormat"),
           let format = AudioFormat(rawValue: formatString) {
            selectedFormat = format
        }
    }
    
    // MARK: - Permission
    
    func requestPermission() {
        audioService.requestPermission()
    }
    
    // MARK: - File Actions
    
    func showInFinder(_ recording: Recording) {
        NSWorkspace.shared.activateFileViewerSelecting([recording.fileURL])
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isShowingError = true
    }
}
