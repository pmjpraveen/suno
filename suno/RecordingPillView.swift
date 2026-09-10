//
//  RecordingPillView.swift
//  suno
//
//  Compact floating pill shown in the FloatingPanel under the menu bar.
//

import SwiftUI

struct RecordingPillView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @EnvironmentObject var menuBarManager: MenuBarManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if !viewModel.hasPermission {
                permissionPill
            } else if viewModel.recordingState == .idle {
                idlePill
            } else {
                activePill
            }
        }
        .padding(.horizontal, 8)
        .frame(width: 240, height: 52)
        .background(Capsule().fill(Color.black))
        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 1.0), value: viewModel.recordingState)
        .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 1.0), value: viewModel.hasPermission)
        .sheet(isPresented: $viewModel.isShowingMeetingPicker) {
            MeetingPickerView(viewModel: viewModel)
        }
        .onChange(of: viewModel.recordingState) { oldValue, newValue in
            menuBarManager.recordingState = newValue
        }
    }

    // MARK: - Idle

    private var idlePill: some View {
        HStack(spacing: 4) {
            Button(action: viewModel.startRecording) {
                HStack(spacing: 8) {
                    Circle().fill(.red).frame(width: 9, height: 9)
                    Text("Record")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(.white.opacity(0.08)))
            }
            .buttonStyle(.pressable)

            circleButton(systemName: "doc.text", action: menuBarManager.showRecordings)
            circleButton(systemName: "gearshape", action: menuBarManager.showSettings)
        }
    }

    // MARK: - Active / Paused

    private var activePill: some View {
        HStack(spacing: 10) {
            Text(viewModel.formattedDuration)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.leading, 10)

            if viewModel.recordingState == .recording {
                WaveformIndicator()
                    .frame(width: 60)
            } else {
                Capsule().fill(.white.opacity(0.15)).frame(width: 60, height: 3)
            }

            Group {
                if viewModel.recordingState == .recording {
                    circleButton(systemName: "pause.fill", iconColor: .black, background: .white, action: viewModel.pauseRecording)
                        .transition(.opacity.combined(with: .scale(scale: 0.7)))
                } else if viewModel.recordingState == .paused {
                    circleButton(systemName: "play.fill", iconColor: .black, background: .white, action: viewModel.resumeRecording)
                        .transition(.opacity.combined(with: .scale(scale: 0.7)))
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 1.0), value: viewModel.recordingState)

            circleButton(systemName: "stop.fill", iconColor: .white, background: .red, action: viewModel.stopRecording)
                .padding(.trailing, 2)
        }
    }

    // MARK: - Permission Needed

    private var permissionPill: some View {
        Button(action: viewModel.requestPermission) {
            HStack(spacing: 8) {
                Image(systemName: "mic.slash.fill")
                    .foregroundStyle(.orange)
                Text("Mic Access Needed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Shared

    private func circleButton(
        systemName: String,
        iconColor: Color = .white.opacity(0.85),
        background: Color = .white.opacity(0.1),
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(Circle().fill(background))
        }
        .buttonStyle(.pressable)
    }
}

#Preview("Idle") {
    RecordingPillView(viewModel: RecordingViewModel())
        .environmentObject(MenuBarManager(
            statusItem: NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
            viewModel: RecordingViewModel()
        ))
        .padding(40)
}
