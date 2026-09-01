//
//  RecordingListView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

struct RecordingListView: View {
    @Environment(RecordingViewModel.self) private var viewModel
    
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
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func deleteRecording(_ recording: Recording) {
        // Show confirmation alert
        let alert = NSAlert()
        alert.messageText = "Delete Recording?"
        alert.informativeText = "This will permanently delete \"\(recording.fileName)\". This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            viewModel.deleteRecording(recording)
        }
    }
}

#Preview {
    RecordingListView()
        .environment(RecordingViewModel())
        .frame(width: 350, height: 300)
}
