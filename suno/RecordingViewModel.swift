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
    private let calendarService = CalendarService()
    private let appMonitor = AppMonitor()
    private let meetingDetector: MeetingDetector
    private let transcriptionService: TranscriptionService
    private let transcriptStorage = TranscriptStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    @Published var recordings: [Recording] = []
    @Published var selectedFormat: AudioFormat = .m4a
    @Published var errorMessage: String?
    @Published var isShowingError = false
    
    // Calendar integration
    @Published var currentMeeting: Meeting?
    @Published var availableMeetings: [Meeting] = []
    @Published var suggestedMeeting: Meeting?
    @Published var hasCalendarPermission: Bool = false
    @Published var isShowingMeetingPicker = false
    @Published var isShowingMeetingPrompt = false
    
    // Transcription
    @Published var transcripts: [UUID: Transcript] = [:]  // Recording ID -> Transcript
    @Published var hasSpeechPermission: Bool = false
    
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
        print("🎬 RecordingViewModel INIT started")
        transcriptionService = AppleSpeechTranscriptionService()
        meetingDetector = MeetingDetector(appMonitor: appMonitor, calendarService: calendarService)
        print("✅ MeetingDetector created")
        loadRecordings()
        loadSelectedFormat()
        loadTranscripts()
        setupCalendarService()
        setupMeetingDetection()
        checkSpeechPermission()
        print("✅ RecordingViewModel INIT complete")
        
        // Force check accessibility permission
        print("🔐 Accessibility permission: \(appMonitor.hasAccessibilityPermission)")
        if !appMonitor.hasAccessibilityPermission {
            print("⚠️ REQUESTING ACCESSIBILITY PERMISSION...")
            appMonitor.requestAccessibilityPermission()
        }
    }
    
    // MARK: - Calendar Setup
    
    private func setupCalendarService() {
        hasCalendarPermission = calendarService.hasPermission
        
        // Observe permission changes
        calendarService.$hasPermission
            .assign(to: &$hasCalendarPermission)
    }
    
    // MARK: - Meeting Detection Setup
    
    private func setupMeetingDetection() {
        meetingDetector.$shouldPromptRecording
            .sink { [weak self] shouldPrompt in
                if shouldPrompt, let meeting = self?.meetingDetector.detectedMeeting {
                    self?.handleMeetingDetected(meeting)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleMeetingDetected(_ meeting: Meeting) {
        // Only prompt if not currently recording
        guard recordingState == .idle else { return }
        
        currentMeeting = meeting
        isShowingMeetingPrompt = true
    }
    
    // MARK: - Calendar Permission
    
    func requestCalendarPermission() {
        Task {
            do {
                let granted = try await calendarService.requestPermission()
                if granted {
                    await fetchTodaysMeetings()
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    // MARK: - Recording Actions
    
    func startRecording() {
        Task {
            do {
                // Fetch meetings if we have permission
                if hasCalendarPermission {
                    await fetchTodaysMeetings()
                    await matchCurrentMeeting()
                } else {
                    // No calendar permission, use unscheduled
                    await MainActor.run {
                        currentMeeting = .unscheduled
                    }
                }
                
                // Start the actual recording
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
                if var recording = try await audioService.stopRecording() {
                    // Associate with current meeting
                    if let meeting = currentMeeting {
                        recording.calendarEventID = meeting.id
                        recording.meetingTitle = meeting.title
                        recording.meetingParticipants = meeting.participants
                    }
                    
                    await MainActor.run {
                        saveRecording(recording)
                        // Auto-start transcription
                        startTranscription(for: recording)
                        // Clear current meeting after saving
                        currentMeeting = nil
                        suggestedMeeting = nil
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
    
    // MARK: - Meeting Prompt Actions
    
    func acceptMeetingPrompt() {
        meetingDetector.acceptMeeting()
        isShowingMeetingPrompt = false
        startRecording()
    }
    
    func declineMeetingPrompt() {
        if let meeting = currentMeeting {
            meetingDetector.declineMeeting(meeting)
        }
        isShowingMeetingPrompt = false
        currentMeeting = nil
    }
    
    // MARK: - Calendar Methods
    
    func fetchTodaysMeetings() async {
        guard hasCalendarPermission else { return }
        
        do {
            let meetings = try await calendarService.fetchTodaysEvents()
            await MainActor.run {
                availableMeetings = meetings
            }
        } catch {
            await MainActor.run {
                handleError(error)
            }
        }
    }
    
    func matchCurrentMeeting() async {
        let now = Date()
        let matched = MeetingMatcher.findBestMatch(at: now, from: availableMeetings)
        
        await MainActor.run {
            if let matched = matched {
                suggestedMeeting = matched
                currentMeeting = matched
            } else {
                suggestedMeeting = nil
                currentMeeting = .unscheduled
            }
        }
    }
    
    func selectMeeting(_ meeting: Meeting) {
        currentMeeting = meeting
        isShowingMeetingPicker = false
    }
    
    func showMeetingPicker() {
        isShowingMeetingPicker = true
    }
    
    func getMeetingForRecording(_ recording: Recording) -> Meeting? {
        guard let eventID = recording.calendarEventID,
              hasCalendarPermission else {
            return nil
        }
        
        if eventID == "unscheduled" {
            return .unscheduled
        }
        
        return calendarService.fetchEvent(withID: eventID)
    }
    
    // MARK: - Transcription Methods
    
    private func checkSpeechPermission() {
        Task {
            hasSpeechPermission = await transcriptionService.checkAvailability()
            print("🎤 Speech recognition available: \(hasSpeechPermission)")
        }
    }
    
    func requestSpeechPermission() {
        Task {
            do {
                let granted = try await transcriptionService.requestPermission()
                await MainActor.run {
                    hasSpeechPermission = granted
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }
    
    private func loadTranscripts() {
        // Load all existing transcripts
        if let allTranscripts = try? transcriptStorage.loadAllTranscripts() {
            for transcript in allTranscripts {
                transcripts[transcript.recordingID] = transcript
            }
            print("📄 Loaded \(allTranscripts.count) transcripts")
        }
    }
    
    func getTranscript(for recording: Recording) -> Transcript? {
        return transcripts[recording.id]
    }
    
    private func startTranscription(for recording: Recording) {
        print("🚀 Auto-starting transcription for: \(recording.fileName)")
        
        // Create pending transcript
        let transcript = Transcript(recordingID: recording.id, status: .pending)
        transcripts[recording.id] = transcript
        
        // Save pending state
        try? transcriptStorage.saveTranscript(transcript)
        
        // Start transcription in background
        Task {
            do {
                // Request permission if not yet granted
                if !hasSpeechPermission {
                    _ = try await transcriptionService.requestPermission()
                    await MainActor.run {
                        hasSpeechPermission = true
                    }
                }
                
                // Update to transcribing status
                await MainActor.run {
                    var updatedTranscript = transcript
                    updatedTranscript.status = .transcribing
                    transcripts[recording.id] = updatedTranscript
                    try? transcriptStorage.saveTranscript(updatedTranscript)
                }
                
                // Perform transcription
                let completedTranscript = try await transcriptionService.transcribe(
                    recording: recording,
                    progressHandler: { progress in
                        Task { @MainActor in
                            if var transcript = self.transcripts[recording.id] {
                                transcript.progress = progress
                                self.transcripts[recording.id] = transcript
                            }
                        }
                    }
                )
                
                // Save completed transcript
                await MainActor.run {
                    transcripts[recording.id] = completedTranscript
                    try? transcriptStorage.saveTranscript(completedTranscript)
                    print("✅ Transcription saved for: \(recording.fileName)")
                }
                
            } catch {
                // Handle transcription failure
                await MainActor.run {
                    var failedTranscript = transcript
                    failedTranscript.status = .failed
                    failedTranscript.errorMessage = error.localizedDescription
                    failedTranscript.completedAt = Date()
                    transcripts[recording.id] = failedTranscript
                    try? transcriptStorage.saveTranscript(failedTranscript)
                    
                    print("❌ Transcription failed: \(error.localizedDescription)")
                    handleError(error)
                }
            }
        }
    }
    
    func retryTranscription(for recording: Recording) {
        print("🔄 Retrying transcription for: \(recording.fileName)")
        
        // Remove old transcript
        transcripts.removeValue(forKey: recording.id)
        try? transcriptStorage.deleteTranscript(for: recording.id)
        
        // Start new transcription
        startTranscription(for: recording)
    }
    
    func cancelTranscription(for recording: Recording) {
        transcriptionService.cancelTranscription(for: recording.id)
        
        if var transcript = transcripts[recording.id] {
            transcript.status = .cancelled
            transcript.completedAt = Date()
            transcripts[recording.id] = transcript
            try? transcriptStorage.saveTranscript(transcript)
        }
    }
}
