//
//  PopoverContentView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

struct PopoverContentView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @EnvironmentObject var menuBarManager: MenuBarManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Recording Controls
            RecordingControlsView(viewModel: viewModel)
            
            Divider()
            
            // Recordings List
            RecordingListView(viewModel: viewModel)
        }
        .frame(width: 350, height: 500)
        .onChange(of: viewModel.recordingState) { _, newState in
            menuBarManager.recordingState = newState
        }
        .onAppear {
            menuBarManager.recordingState = viewModel.recordingState
        }
    }
}
