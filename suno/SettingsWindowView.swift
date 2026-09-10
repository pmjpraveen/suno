//
//  SettingsWindowView.swift
//  suno
//

import SwiftUI

struct SettingsWindowView: View {
    @ObservedObject var viewModel: RecordingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Permissions Section
                section(title: "Permissions") {
                    VStack(spacing: 12) {
                        // Microphone Permission
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Microphone")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(viewModel.hasPermission ? "Granted" : "Not Granted")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if !viewModel.hasPermission {
                                Button("Grant") {
                                    viewModel.requestPermission()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)

                        // Accessibility Permission (for meeting detection)
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Accessibility")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("For meeting detection")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Configure") {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)

                        // System Audio Permission (captures meeting participants cleanly,
                        // instead of the mic re-picking up speaker output)
                        HStack {
                            Image(systemName: "waveform.badge.person.fill")
                                .foregroundStyle(.teal)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("System Audio")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Captures meeting audio cleanly, not through the mic")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if viewModel.hasSystemAudioPermission {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button("Configure") {
                                    viewModel.requestSystemAudioPermission()
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                }

                // Audio Format Section
                section(title: "Audio Format") {
                    Picker("Format", selection: $viewModel.selectedFormat) {
                        ForEach(AudioFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }

                // Language Section
                section(title: "Transcription") {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(.purple)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Language")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Used for speech-to-text transcription")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Picker("Language", selection: $viewModel.selectedLanguage) {
                            Text("\(Language.auto.flag) Auto-Detect").tag(Language.auto)

                            Section("Indian Languages") {
                                ForEach(Language.indianLanguages) { language in
                                    Text("\(language.flag) \(language.displayName)").tag(language)
                                }
                            }

                            Section("International") {
                                ForEach(Language.internationalLanguages) { language in
                                    Text("\(language.flag) \(language.displayName)").tag(language)
                                }
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 160)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }

                Spacer(minLength: 20)

                // Quit Button
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit Suno")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.pressable)
            }
            .padding(20)
        }
        .frame(minWidth: 380, minHeight: 420)
        .onAppear {
            viewModel.refreshSystemAudioPermission()
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content()
        }
    }
}

#Preview {
    SettingsWindowView(viewModel: RecordingViewModel())
}
