//
//  RecordingRowView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

struct RecordingRowView: View {
    let recording: Recording
    let onDelete: () -> Void
    let onShowInFinder: () -> Void
    let onSelect: (() -> Void)?
    var transcript: Transcript? = nil
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: recording.hasMeeting ? "calendar.badge.checkmark" : "waveform")
                .font(.title3)
                .foregroundStyle(recording.hasMeeting ? .blue : .gray)
                .frame(width: 24)
            
            // Recording Info
            VStack(alignment: .leading, spacing: 4) {
                // Meeting title or filename
                Text(recording.displayTitle)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(relativeDate(for: recording.startTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(recording.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(recording.format.fileExtension.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Participants if available
                if let participants = recording.meetingParticipants, !participants.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption2)
                        Text(participantsText(participants))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                
                // Transcript status indicator
                if let transcript = transcript {
                    transcriptStatusIndicator(for: transcript.status)
                }
            }
            
            Spacer()
            
            // Actions (visible on hover)
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: onShowInFinder) {
                        Image(systemName: "folder")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Show in Finder")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete Recording")
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelect?()
        }
        .contextMenu {
            Button("Show in Finder") {
                onShowInFinder()
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func relativeDate(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: date))"
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let weekday = calendar.component(.weekday, from: date)
            let weekdayName = DateFormatter().weekdaySymbols[weekday - 1]
            return "\(weekdayName), \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func participantsText(_ participants: [String]) -> String {
        if participants.count <= 2 {
            return participants.joined(separator: ", ")
        } else {
            return "\(participants.count) participants"
        }
    }
    
    @ViewBuilder
    private func transcriptStatusIndicator(for status: TranscriptionStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.displayText)
                .font(.caption2)
        }
        .foregroundStyle(statusColor(for: status))
    }
    
    private func statusColor(for status: TranscriptionStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .transcribing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

#Preview {
    VStack {
        RecordingRowView(
            recording: Recording(
                fileName: "Meeting Recording.m4a",
                fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
                format: .m4a,
                startTime: Date(),
                duration: 1234,
                fileSize: 5_000_000
            ),
            onDelete: {},
            onShowInFinder: {},
            onSelect: {}
        )
        
        RecordingRowView(
            recording: Recording(
                fileName: "Team Standup.wav",
                fileURL: URL(fileURLWithPath: "/tmp/test.wav"),
                format: .wav,
                startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                duration: 567,
                fileSize: 12_000_000
            ),
            onDelete: {},
            onShowInFinder: {},
            onSelect: {}
        )
    }
    .frame(width: 350)
    .padding()
}
