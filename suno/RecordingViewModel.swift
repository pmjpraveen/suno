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
    private let transcriptionService: AppleSpeechTranscriptionService
    private let transcriptStorage = TranscriptStorageService.shared
    private let aiAnalysisService = AppleIntelligenceService()
    private let analysisStorage = MeetingAnalysisStorageService.shared
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
    @Published var selectedLanguage: Language = .auto
    
    // AI Analysis
    @Published var analyses: [UUID: MeetingAnalysis] = [:]  // Transcript ID -> Analysis
    @Published var hasAIAnalysisAvailable: Bool = false
    
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
        currentDuration.formattedDuration
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
        loadAnalyses()
        setupCalendarService()
        setupMeetingDetection()
        checkSpeechPermission()
        checkAIAnalysisAvailability()
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
            // Delete the recording and associated files from storage
            try storageService.deleteRecording(recording, from: &recordings)
            
            // Remove associated transcript from memory
            transcripts.removeValue(forKey: recording.id)
            
            // Remove associated analysis from memory
            if let transcript = transcripts[recording.id] {
                analyses.removeValue(forKey: transcript.id)
            }
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
        print("🌍 Language: \(selectedLanguage.displayName)")
        
        // Create pending transcript
        let transcript = Transcript(
            recordingID: recording.id,
            status: TranscriptionStatus.pending,
            requestedLanguage: selectedLanguage
        )
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
                    updatedTranscript.status = TranscriptionStatus.transcribing
                    transcripts[recording.id] = updatedTranscript
                    try? transcriptStorage.saveTranscript(updatedTranscript)
                }
                
                // Perform transcription with selected language
                let completedTranscript = try await transcriptionService.transcribe(
                    recording: recording,
                    language: selectedLanguage,
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
                    
                    // Automatically start AI analysis after transcription completes
                    if hasAIAnalysisAvailable {
                        print("🧠 Auto-starting AI analysis...")
                        startAnalysis(for: recording)
                    }
                }
                
            } catch {
                // Handle transcription failure
                await MainActor.run {
                    var failedTranscript = transcript
                    failedTranscript.status = TranscriptionStatus.failed
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
            transcript.status = TranscriptionStatus.cancelled
            transcript.completedAt = Date()
            transcripts[recording.id] = transcript
            try? transcriptStorage.saveTranscript(transcript)
        }
    }
    
    // MARK: - AI Analysis
    
    private func loadAnalyses() {
        do {
            let loadedAnalyses = try analysisStorage.loadAllAnalyses()
            for analysis in loadedAnalyses {
                analyses[analysis.transcriptId] = analysis
            }
            print("📚 Loaded \(loadedAnalyses.count) AI analyses")
        } catch {
            print("⚠️ Failed to load analyses: \(error)")
        }
    }
    
    private func checkAIAnalysisAvailability() {
        Task {
            let available = await aiAnalysisService.checkAvailability()
            await MainActor.run {
                hasAIAnalysisAvailable = available
                print("🧠 AI Analysis available: \(available)")
                
                if !available {
                    print("⚠️ Apple Intelligence is unavailable. Enable it in System Settings > Apple Intelligence & Siri.")
                }
            }
        }
    }
    
    func getAnalysis(for transcript: Transcript) -> MeetingAnalysis? {
        return analyses[transcript.id]
    }
    
    func startAnalysis(for recording: Recording) {
        guard let transcript = transcripts[recording.id] else {
            print("⚠️ No transcript found for recording: \(recording.id)")
            return
        }
        
        guard transcript.status == .completed else {
            print("⚠️ Transcript not completed yet")
            return
        }
        
        guard hasAIAnalysisAvailable else {
            print("⚠️ AI Analysis not available")
            handleError(AIAnalysisError.serviceUnavailable)
            return
        }
        
        // Get meeting context
        let meeting: Meeting?
        if let eventID = recording.calendarEventID, eventID != "unscheduled" {
            meeting = availableMeetings.first { $0.id == eventID }
        } else {
            meeting = nil
        }
        
        Task {
            do {
                // Create pending analysis
                var analysis = MeetingAnalysis(
                    meetingId: recording.calendarEventID ?? "unscheduled",
                    transcriptId: transcript.id,
                    status: .pending
                )
                
                await MainActor.run {
                    analyses[transcript.id] = analysis
                }
                
                print("🧠 Starting AI analysis for transcript: \(transcript.id)")
                
                // Update to analyzing
                analysis.status = .analyzing
                analysis.updatedAt = Date()
                try analysisStorage.saveAnalysis(analysis)
                
                await MainActor.run {
                    analyses[transcript.id] = analysis
                }
                
                // Perform analysis
                let response = try await aiAnalysisService.analyzeTranscript(
                    transcript,
                    meeting: meeting
                )
                
                // Convert response to analysis
                // Note: We create a new analysis with the existing ID to preserve identity
                let responseAnalysis = response.toMeetingAnalysis(
                    meetingId: recording.calendarEventID ?? "unscheduled",
                    transcriptId: transcript.id
                )
                
                // Create completed analysis preserving the original ID
                let completedAnalysis = MeetingAnalysis(
                    id: analysis.id,  // Preserve the existing ID
                    meetingId: responseAnalysis.meetingId,
                    transcriptId: responseAnalysis.transcriptId,
                    overview: responseAnalysis.overview,
                    keyPoints: responseAnalysis.keyPoints,
                    decisions: responseAnalysis.decisions,
                    actionItems: responseAnalysis.actionItems,
                    mom: responseAnalysis.mom,
                    status: .completed,
                    createdAt: analysis.createdAt,
                    updatedAt: Date()
                )
                
                // Save and publish
                try analysisStorage.saveAnalysis(completedAnalysis)
                
                await MainActor.run {
                    analyses[transcript.id] = completedAnalysis
                    print("✅ AI analysis completed!")
                }
                
            } catch {
                print("❌ AI analysis failed: \(error.localizedDescription)")
                
                var failedAnalysis = analyses[transcript.id] ?? MeetingAnalysis(
                    meetingId: recording.calendarEventID ?? "unscheduled",
                    transcriptId: transcript.id
                )
                
                failedAnalysis.status = .failed
                failedAnalysis.errorMessage = error.localizedDescription
                failedAnalysis.updatedAt = Date()
                
                try? analysisStorage.saveAnalysis(failedAnalysis)
                
                await MainActor.run {
                    analyses[transcript.id] = failedAnalysis
                    handleError(error)
                }
            }
        }
    }
    
    func retryAnalysis(for recording: Recording) {
        guard let transcript = transcripts[recording.id] else { return }
        
        print("🔄 Retrying AI analysis for transcript: \(transcript.id)")
        
        // Reset status to pending
        if var analysis = analyses[transcript.id] {
            analysis.status = .pending
            analysis.errorMessage = nil
            analysis.updatedAt = Date()
            analyses[transcript.id] = analysis
            try? analysisStorage.saveAnalysis(analysis)
        }
        
        // Start new analysis
        startAnalysis(for: recording)
    }
    
    func toggleActionItemCompletion(_ actionItemId: UUID, in transcriptId: UUID) {
        guard var analysis = analyses[transcriptId] else { return }
        
        do {
            try analysisStorage.toggleActionItemCompletion(actionItemId, in: analysis)
            
            // Reload from storage to get updated version
            if let updated = try analysisStorage.loadAnalysis(for: transcriptId) {
                analyses[transcriptId] = updated
            }
        } catch {
            print("❌ Failed to toggle action item: \(error)")
            handleError(error)
        }
    }
}

