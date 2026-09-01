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
        VStack(spacing: 16) {
            // Recording State Indicator
            HStack(spacing: 12) {
                // State icon with animation
                RecordingStateIndicator(state: viewModel.recordingState)
                
                // Duration display
                Text(viewModel.formattedDuration)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.recordingState == .recording ? .red : .primary)
                
                Spacer()
            }
            
            // Control Buttons
            HStack(spacing: 12) {
                if viewModel.canStartRecording {
                    // Start Recording Button
                    Button(action: viewModel.startRecording) {
                        Label("Start Recording", systemImage: "record.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                } else if viewModel.canPauseRecording {
                    // Pause Button
                    Button(action: viewModel.pauseRecording) {
                        Label("Pause", systemImage: "pause.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.large)
                    
                    // Stop Button
                    Button(action: viewModel.stopRecording) {
                        Label("Stop", systemImage: "stop.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                } else if viewModel.canResumeRecording {
                    // Resume Button
                    Button(action: viewModel.resumeRecording) {
                        Label("Resume", systemImage: "play.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .controlSize(.large)
                    
                    // Stop Button
                    Button(action: viewModel.stopRecording) {
                        Label("Stop", systemImage: "stop.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
            }
            
            // Format Selector (only when idle)
            if viewModel.recordingState == .idle {
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
                    .frame(maxWidth: 200)
                }
            }
            
            // Permission Warning
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
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Recording State Indicator

struct RecordingStateIndicator: View {
    let state: RecordingState
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(stateColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(stateColor, lineWidth: 2)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0.0 : 0.8)
            )
            .onAppear {
                if state == .recording {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
            }
            .onChange(of: state) { oldValue, newValue in
                if newValue == .recording {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                } else {
                    isAnimating = false
                }
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
}

#Preview {
    RecordingControlsView(viewModel: RecordingViewModel())
        .frame(width: 350)
        .padding()
}
