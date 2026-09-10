//
//  ActionItemRow.swift
//  suno
//

import SwiftUI

struct ActionItemRow: View {
    let actionItem: ActionItem
    let onToggle: ((UUID) -> Void)?
    let onSeek: ((TimeInterval) -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: {
                onToggle?(actionItem.id)
            }) {
                Image(systemName: actionItem.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(actionItem.completed ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.pressable)
            .help(actionItem.completed ? "Mark as incomplete" : "Mark as complete")
            
            VStack(alignment: .leading, spacing: 6) {
                // Task text
                Text(actionItem.task)
                    .font(.body)
                    .foregroundStyle(actionItem.completed ? .secondary : .primary)
                    .strikethrough(actionItem.completed)
                
                // Metadata
                HStack(spacing: 12) {
                    // Assignee
                    if let assignee = actionItem.assignee {
                        Label(assignee, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Due date
                    if let dueDate = actionItem.formattedDueDate {
                        Label(dueDate, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(actionItem.isOverdue ? .red : .secondary)
                    }
                    
                    // Timestamp link
                    if let timestamp = actionItem.formattedTimestamp, let onSeek = onSeek {
                        Button(action: {
                            if let ts = actionItem.sourceTimestamp {
                                onSeek(ts)
                            }
                        }) {
                            Label(timestamp, systemImage: "waveform")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.blue)
                        .help("Jump to this moment in the recording")
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    VStack(spacing: 16) {
        ActionItemRow(
            actionItem: ActionItem(
                task: "Follow up with design team on new mockups",
                assignee: "Sarah",
                dueDate: Date().addingTimeInterval(86400 * 7),
                sourceTimestamp: 325.5,
                completed: false
            ),
            onToggle: { _ in },
            onSeek: { _ in }
        )
        
        ActionItemRow(
            actionItem: ActionItem(
                task: "Review and approve budget proposal",
                assignee: nil,
                dueDate: Date().addingTimeInterval(-86400),
                sourceTimestamp: 892.3,
                completed: true
            ),
            onToggle: { _ in },
            onSeek: { _ in }
        )
        
        ActionItemRow(
            actionItem: ActionItem(
                task: "Schedule next sprint planning meeting",
                assignee: "Mike",
                dueDate: nil,
                sourceTimestamp: nil,
                completed: false
            ),
            onToggle: { _ in },
            onSeek: nil
        )
    }
    .padding()
    .frame(width: 500)
}
