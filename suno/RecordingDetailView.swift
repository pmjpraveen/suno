//
//  RecordingDetailView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI
import AVFoundation

struct RecordingDetailView: View {
    let recording: Recording
    @ObservedObject var viewModel: RecordingViewModel
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var playbackTimer: Timer?
    
    var transcript: Transcript? {
        viewModel.getTranscript(for: recording)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                Divider()
                
                // Recording Info
                recordingInfoSection
                
                // Audio Player
                audioPlayerSection
                
                // Transcript
                TranscriptView(
                    transcript: transcript,
                    recording: recording,
                    onRetry: {
                        viewModel.retryTranscription(for: recording)
                    },
                    onCancel: {
                        viewModel.cancelTranscription(for: recording)
                    },
                    onSeek: { time in
                        seekTo(time)
                    }
                )
            }
            .padding(20)
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recording.hasMeeting ? "calendar.badge.checkmark" : "waveform")
                    .font(.title2)
                    .foregroundStyle(recording.hasMeeting ? .blue : .gray)
                
                Text(recording.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if let participants = recording.meetingParticipants, !participants.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(participants.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Recording Info Section
    
    private var recordingInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recording Details")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("Duration:")
                        .foregroundStyle(.secondary)
                    Text(recording.formattedDuration)
                }
                
                GridRow {
                    Text("Format:")
                        .foregroundStyle(.secondary)
                    Text(recording.format.displayName)
                }
                
                GridRow {
                    Text("File Size:")
                        .foregroundStyle(.secondary)
                    Text(recording.formattedFileSize)
                }
                
                GridRow {
                    Text("Recorded:")
                        .foregroundStyle(.secondary)
                    Text(recording.formattedStartTime)
                }
                
                GridRow {
                    Text("File:")
                        .foregroundStyle(.secondary)
                    Text(recording.fileName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Audio Player Section
    
    private var audioPlayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playback")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Progress Bar
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { currentTime },
                            set: { newValue in
                                seekTo(newValue)
                            }
                        ),
                        in: 0...recording.duration
                    )
                    
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        
                        Spacer()
                        
                        Text(formatTime(recording.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                
                // Playback Controls
                HStack(spacing: 16) {
                    Button(action: {
                        skipBackward()
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .help("Skip backward 10 seconds")
                    
                    Button(action: {
                        togglePlayback()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.borderless)
                    .help(isPlaying ? "Pause" : "Play")
                    
                    Button(action: {
                        skipForward()
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .help("Skip forward 10 seconds")
                    
                    Spacer()
                    
                    Button(action: {
                        showInFinder()
                    }) {
                        Image(systemName: "folder")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .help("Show in Finder")
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Audio Player Methods
    
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to setup audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        guard let player = audioPlayer else { return }
        
        if isPlaying {
            player.pause()
            stopTimer()
        } else {
            player.play()
            startTimer()
        }
        
        isPlaying.toggle()
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        stopTimer()
        isPlaying = false
    }
    
    private func seekTo(_ time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        
        if !isPlaying {
            audioPlayer?.play()
            isPlaying = true
            startTimer()
        }
    }
    
    private func skipBackward() {
        let newTime = max(0, currentTime - 10)
        seekTo(newTime)
    }
    
    private func skipForward() {
        let newTime = min(recording.duration, currentTime + 10)
        seekTo(newTime)
    }
    
    private func startTimer() {
        stopTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer {
                currentTime = player.currentTime
                
                // Stop when finished
                if !player.isPlaying {
                    isPlaying = false
                    stopTimer()
                }
            }
        }
    }
    
    private func stopTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func showInFinder() {
        viewModel.showInFinder(recording)
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview {
    RecordingDetailView(
        recording: Recording(
            fileName: "Team Meeting.m4a",
            fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            format: .m4a,
            startTime: Date(),
            duration: 1800,
            fileSize: 5_000_000,
            meetingTitle: "Product Planning Meeting",
            meetingParticipants: ["Alice", "Bob", "Charlie"]
        ),
        viewModel: RecordingViewModel()
    )
}
