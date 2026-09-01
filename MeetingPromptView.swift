//
//  MeetingPromptView.swift
//  suno
//

import SwiftUI

struct MeetingPromptView: View {
    let meeting: Meeting
    let onStartRecording: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Meeting Detected")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(meeting.title)
                        .font(.body)
                }
                
                HStack {
                    Image(systemName: "app.fill")
                        .foregroundStyle(.secondary)
                    Text(meeting.source.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !meeting.participants.isEmpty {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundStyle(.secondary)
                        Text(meeting.participantsString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("Would you like to start recording this meeting?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Not Now") {
                    onDecline()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Start Recording") {
                    onStartRecording()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
