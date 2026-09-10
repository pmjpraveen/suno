//
//  RecordingListView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI
import AppKit

struct RecordingListView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recordings")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.recordings.isEmpty {
                    Text("\(viewModel.recordings.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // List Content
            if viewModel.recordings.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray.opacity(0.5))
                    
                    Text("No Recordings Yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Start recording to see your meetings here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Recordings List
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.recordings) { recording in
                            RecordingRowView(
                                recording: recording,
                                onDelete: {
                                    deleteRecording(recording)
                                },
                                onShowInFinder: {
                                    viewModel.showInFinder(recording)
                                },
                                onSelect: {
                                    openDetailWindow(for: recording)
                                },
                                transcript: viewModel.getTranscript(for: recording)
                            )
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                    .padding(.vertical, 8)
                    .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 1.0), value: viewModel.recordings.map(\.id))
                }
            }
        }
    }
    
    private func deleteRecording(_ recording: Recording) {
        // Show confirmation alert on main thread
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Delete Recording?"
            alert.informativeText = "This will permanently delete \"\(recording.displayTitle)\" and any associated transcripts or analysis. This action cannot be undone."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // Perform deletion
                self.viewModel.deleteRecording(recording)
            }
        }
    }
    
    private func openDetailWindow(for recording: Recording) {
        let detailView = RecordingDetailView(recording: recording, viewModel: viewModel)
        let hostingController = NSHostingController(rootView: detailView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = recording.displayTitle
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 700, height: 600))
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Keep window alive
        window.isReleasedWhenClosed = false
    }
}

#Preview {
    RecordingListView(viewModel: RecordingViewModel())
        .frame(width: 350, height: 300)
}
