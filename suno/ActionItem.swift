//
//  ActionItem.swift
//  suno
//

import Foundation

struct ActionItem: Identifiable, Codable, Equatable {
    let id: UUID
    let task: String
    var assignee: String?  // Only if explicitly mentioned in transcript
    var dueDate: Date?  // Only if explicitly mentioned
    var sourceTimestamp: TimeInterval?  // Timestamp in the recording/transcript
    var completed: Bool
    
    init(
        id: UUID = UUID(),
        task: String,
        assignee: String? = nil,
        dueDate: Date? = nil,
        sourceTimestamp: TimeInterval? = nil,
        completed: Bool = false
    ) {
        self.id = id
        self.task = task
        self.assignee = assignee
        self.dueDate = dueDate
        self.sourceTimestamp = sourceTimestamp
        self.completed = completed
    }
    
    // MARK: - Computed Properties
    
    var formattedTimestamp: String? {
        guard let timestamp = sourceTimestamp else { return nil }
        
        let hours = Int(timestamp) / 3600
        let minutes = Int(timestamp) / 60 % 60
        let seconds = Int(timestamp) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedDueDate: String? {
        guard let dueDate = dueDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: dueDate)
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !completed && dueDate < Date()
    }
    
    var displayAssignee: String {
        assignee ?? "Unassigned"
    }
}
