//
//  RecordingControlsView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

struct RecordingControlsView: View {
    @ObservedObject var viewModel: RecordingViewModel
    
    var body: some View {
        VStack(spacing: Layout.mainSpacing) {
            meetingBadgeSection
            recordingStatusSection
            controlButtonsSection
            formatSelectorSection
            permissionWarningSection
        }
        .sheet(isPresented: $viewModel.isShowingMeetingPicker) {
            MeetingPickerView(viewModel: viewModel)
        }
    }
    
    // MARK: - Meeting Badge Section
    
    @ViewBuilder
    private var meetingBadgeSection: some View {
        if viewModel.recordingState != .idle, let meeting = viewModel.currentMeeting {
            HStack {
                MeetingBadgeView(meeting: meeting, compact: false)
                
                if viewModel.recordingState != .stopped {
                    Button(action: viewModel.showMeetingPicker) {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                    .help("Change Meeting")
                    .accessibilityLabel("Edit meeting")
                }
            }
        }
    }
    
    // MARK: - Recording Status Section
    
    private var recordingStatusSection: some View {
        HStack(spacing: Layout.statusSpacing) {
            RecordingStateIndicator(state: viewModel.recordingState)
                .accessibilityLabel("Recording status")
                .accessibilityValue(viewModel.recordingState.accessibilityDescription)
            
            Text(viewModel.formattedDuration)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(viewModel.recordingState == .recording ? .red : .primary)
                .accessibilityLabel("Duration")
            
            Spacer()
        }
    }
    
    // MARK: - Control Buttons Section
    
    @ViewBuilder
    private var controlButtonsSection: some View {
        HStack(spacing: Layout.buttonSpacing) {
            switch viewModel.recordingState {
            case .idle, .stopped:
                if viewModel.canStartRecording {
                    startRecordingButton
                }
            case .recording:
                if viewModel.canPauseRecording {
                    pauseButton
                    stopButton
                }
            case .paused:
                if viewModel.canResumeRecording {
                    resumeButton
                    stopButton
                }
            }
        }
    }
    
    // MARK: - Format Selector Section
    
    @ViewBuilder
    private var formatSelectorSection: some View {
        if viewModel.recordingState == .idle {
            VStack(alignment: .leading, spacing: Layout.formatSpacing) {
                // Audio Format
                HStack {
                    Text("Format:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Format", selection: $viewModel.selectedFormat) {
                        ForEach(AudioFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: Layout.formatPickerMaxWidth)
                    .accessibilityLabel("Audio format")
                }
                
                // Language Selector
                HStack {
                    Text("Language:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Language", selection: $viewModel.selectedLanguage) {
                        // Popular languages
                        ForEach(Language.popular, id: \.self) { language in
                            Text(language.nativeDisplayName).tag(language)
                        }
                        
                        Divider()
                        
                        // Indian Languages Section
                        Section(header: Text("Indian Languages")) {
                            ForEach(Language.indianLanguages, id: \.self) { language in
                                Text(language.nativeDisplayName).tag(language)
                            }
                        }
                        
                        Divider()
                        
                        // International Languages
                        Section(header: Text("International")) {
                            ForEach(Language.internationalLanguages, id: \.self) { language in
                                Text(language.nativeDisplayName).tag(language)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: Layout.languagePickerMaxWidth)
                    .accessibilityLabel("Transcription language")
                    .help("Select the primary language spoken in your meeting")
                }
            }
        }
    }
    
    // MARK: - Permission Warning Section
    
    @ViewBuilder
    private var permissionWarningSection: some View {
        if !viewModel.hasPermission {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Microphone permission required")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Grant") {
                    viewModel.requestPermission()
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
            .padding(Layout.warningPadding)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(Layout.warningCornerRadius)
            .accessibilityElement(children: .combine)
        }
    }
    
    // MARK: - Button Components
    
    @ViewBuilder
    private var startRecordingButton: some View {
        Button(action: viewModel.startRecording) {
            Label("Start Recording", systemImage: "record.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .controlSize(.large)
        .disabled(!viewModel.hasPermission)
        .accessibilityHint("Begins audio recording")
    }
    
    @ViewBuilder
    private var pauseButton: some View {
        Button(action: viewModel.pauseRecording) {
            Label("Pause", systemImage: "pause.circle.fill")
        }
        .buttonStyle(.bordered)
        .tint(.orange)
        .controlSize(.large)
        .accessibilityHint("Pauses current recording")
    }
    
    @ViewBuilder
    private var resumeButton: some View {
        Button(action: viewModel.resumeRecording) {
            Label("Resume", systemImage: "play.circle.fill")
        }
        .buttonStyle(.bordered)
        .tint(.green)
        .controlSize(.large)
        .accessibilityHint("Resumes paused recording")
    }
    
    @ViewBuilder
    private var stopButton: some View {
        Button(action: viewModel.stopRecording) {
            Label("Stop", systemImage: "stop.circle.fill")
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .controlSize(.large)
        .accessibilityHint("Stops and saves recording")
    }
}

// MARK: - Layout Constants

private enum Layout {
    static let mainSpacing: CGFloat = 16
    static let statusSpacing: CGFloat = 12
    static let buttonSpacing: CGFloat = 12
    static let formatSpacing: CGFloat = 8
    static let formatPickerMaxWidth: CGFloat = 200
    static let languagePickerMaxWidth: CGFloat = 200
    static let warningPadding: CGFloat = 8
    static let warningCornerRadius: CGFloat = 8
    static let indicatorSize: CGFloat = 12
    static let indicatorStrokeWidth: CGFloat = 2
    static let indicatorAnimationDuration: TimeInterval = 1.0
    static let indicatorScaleEffect: CGFloat = 1.5
}

// MARK: - Recording State Indicator

struct RecordingStateIndicator: View {
    let state: RecordingState
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(stateColor)
            .frame(width: Layout.indicatorSize, height: Layout.indicatorSize)
            .overlay(
                Circle()
                    .stroke(stateColor, lineWidth: Layout.indicatorStrokeWidth)
                    .scaleEffect(isAnimating ? Layout.indicatorScaleEffect : 1.0)
                    .opacity(isAnimating ? 0.0 : 0.8)
            )
            .onAppear {
                updateAnimation(for: state)
            }
            .onChange(of: state) { oldValue, newValue in
                updateAnimation(for: newValue)
            }
    }
    
    private var stateColor: Color {
        switch state {
        case .idle, .stopped:
            return .gray
        case .recording:
            return .red
        case .paused:
            return .orange
        }
    }
    
    private func updateAnimation(for state: RecordingState) {
        if state == .recording {
            withAnimation(
                .easeInOut(duration: Layout.indicatorAnimationDuration)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAnimating = false
            }
        }
    }
}

// MARK: - RecordingState Extension

extension RecordingState {
    var accessibilityDescription: String {
        switch self {
        case .idle:
            return "Ready to record"
        case .recording:
            return "Currently recording"
        case .paused:
            return "Recording paused"
        case .stopped:
            return "Recording stopped"
        }
    }
}

// MARK: - Preview

#Preview {
    RecordingControlsView(viewModel: RecordingViewModel())
        .frame(width: 350)
        .padding()
}
