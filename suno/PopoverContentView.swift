//
//  PopoverContentView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

struct PopoverContentView: View {
    @State private var viewModel = RecordingViewModel()
    @EnvironmentObject var menuBarManager: MenuBarManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Recording Controls Section
            RecordingControlsView()
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Recordings List Section
            RecordingListView()
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
        .environment(viewModel)
        .alert("Error", isPresented: $viewModel.isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
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
    PopoverContentView()
        .environmentObject(MenuBarManager(statusItem: NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength), popover: nil))
}

