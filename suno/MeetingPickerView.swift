//
//  MeetingPickerView.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import SwiftUI

struct MeetingPickerView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Meeting")
                    .font(.headline)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Meeting list
            if viewModel.availableMeetings.isEmpty && !viewModel.hasCalendarPermission {
                // No calendar permission
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    
                    Text("Calendar Access Required")
                        .font(.headline)
                    
                    Text("Grant calendar access to automatically associate recordings with your meetings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Grant Access") {
                        viewModel.requestCalendarPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(getMeetingsForSelection()) { meeting in
                            MeetingRow(
                                meeting: meeting,
                                isSelected: viewModel.currentMeeting?.id == meeting.id,
                                isSuggested: viewModel.suggestedMeeting?.id == meeting.id
                            ) {
                                viewModel.selectMeeting(meeting)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 450, height: 500)
    }
    
    private func getMeetingsForSelection() -> [Meeting] {
        MeetingMatcher.getMeetingsForSelection(
            from: viewModel.availableMeetings,
            includeUnscheduled: true
        )
    }
}

// MARK: - Meeting Row

struct MeetingRow: View {
    let meeting: Meeting
    let isSelected: Bool
    let isSuggested: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(meeting.title)
                            .font(.body)
                            .fontWeight(isSelected ? .semibold : .regular)
                        
                        if isSuggested && !isSelected {
                            Text("SUGGESTED")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    if !meeting.isUnscheduled {
                        Text(meeting.formattedTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !meeting.participants.isEmpty {
                            Text(meeting.participantsString)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No associated calendar event")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
        if meeting.isUnscheduled {
            return "calendar.badge.exclamationmark"
        } else if meeting.isHappening {
            return "calendar.badge.clock"
        } else {
            return "calendar"
        }
    }
    
    private var iconColor: Color {
        if meeting.isUnscheduled {
            return .orange
        } else if meeting.isHappening {
            return .green
        } else {
            return .blue
        }
    }
}

#Preview {
    MeetingPickerView(viewModel: RecordingViewModel())
}
