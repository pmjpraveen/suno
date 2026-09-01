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
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            // Recording Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.fileName)
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
            onShowInFinder: {}
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
            onShowInFinder: {}
        )
    }
    .frame(width: 350)
    .padding()
}
