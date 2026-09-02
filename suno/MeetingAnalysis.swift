//
//  MeetingAnalysis.swift
//  suno
//

import Foundation

struct MeetingAnalysis: Identifiable, Codable {
    let id: UUID
    let meetingId: String
    let transcriptId: UUID
    var overview: String
    var keyPoints: [String]
    var decisions: [Decision]
    var actionItems: [ActionItem]
    var mom: String  // Minutes of Meeting
    var status: AnalysisStatus
    let createdAt: Date
    var updatedAt: Date
    var errorMessage: String?
    
    init(
        id: UUID = UUID(),
        meetingId: String,
        transcriptId: UUID,
        overview: String = "",
        keyPoints: [String] = [],
        decisions: [Decision] = [],
        actionItems: [ActionItem] = [],
        mom: String = "",
        status: AnalysisStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        errorMessage: String? = nil
    ) {
        self.id = id
        self.meetingId = meetingId
        self.transcriptId = transcriptId
        self.overview = overview
        self.keyPoints = keyPoints
        self.decisions = decisions
        self.actionItems = actionItems
        self.mom = mom
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.errorMessage = errorMessage
    }
    
    // MARK: - Computed Properties
    
    var isComplete: Bool {
        status == .completed
    }
    
    var isInProgress: Bool {
        status == .analyzing
    }
    
    var hasFailed: Bool {
        status == .failed
    }
    
    var canRetry: Bool {
        status == .failed || status == .pending
    }
    
    var hasContent: Bool {
        !overview.isEmpty || !keyPoints.isEmpty || !decisions.isEmpty || !actionItems.isEmpty
    }
    
    var pendingActionItems: [ActionItem] {
        actionItems.filter { !$0.completed }
    }
    
    var completedActionItems: [ActionItem] {
        actionItems.filter { $0.completed }
    }
    
    var overdueActionItems: [ActionItem] {
        actionItems.filter { $0.isOverdue }
    }
}
