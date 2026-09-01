//
//  PopoverContentView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI
import AppKit

struct PopoverContentView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @EnvironmentObject var menuBarManager: MenuBarManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Recording Controls Section
            RecordingControlsView(viewModel: viewModel)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Recordings List Section
            RecordingListView(viewModel: viewModel)
                .frame(height: 300)
            
            Divider()
            
            // Footer
            HStack(spacing: 12) {
                Button("Quit Suno") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("v1.0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 350)
        .alert("Error", isPresented: $viewModel.isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $viewModel.isShowingMeetingPrompt) {
            if let meeting = viewModel.currentMeeting {
                MeetingPromptView(
                    meeting: meeting,
                    onStartRecording: {
                        viewModel.acceptMeetingPrompt()
                    },
                    onDecline: {
                        viewModel.declineMeetingPrompt()
                    }
                )
            }
        }
        .onChange(of: viewModel.recordingState) { oldValue, newValue in
            // Update menu bar icon when recording state changes
            menuBarManager.recordingState = newValue
        }
        .onAppear {
            // Sync initial state
            menuBarManager.recordingState = viewModel.recordingState
        }
    }
}

#Preview {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()
    let manager = MenuBarManager(statusItem: statusItem, popover: popover)
    
    return PopoverContentView()
        .environmentObject(manager)
}

