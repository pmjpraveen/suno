//
//  AIAnalysisResponse.swift
//  suno
//

import Foundation

/// Structured response from the LLM for meeting analysis
struct AIAnalysisResponse: Codable {
    let overview: String
    let keyPoints: [String]
    let decisions: [AIDecision]
    let actionItems: [AIActionItem]
    let mom: String
    
    /// Decision as returned by AI
    struct AIDecision: Codable {
        let text: String
        let timestamp: Double?  // Timestamp in seconds, if available
    }
    
    /// Action item as returned by AI
    struct AIActionItem: Codable {
        let task: String
        let assignee: String?
        let dueDate: String?  // ISO8601 or natural language
        let timestamp: Double?  // Timestamp in seconds, if available
    }
    
    // MARK: - Conversion
    
    func toMeetingAnalysis(meetingId: String, transcriptId: UUID, id: UUID = UUID()) -> MeetingAnalysis {
        let decisions = self.decisions.map { aiDecision in
            Decision(
                text: aiDecision.text,
                sourceTimestamp: aiDecision.timestamp
            )
        }
        
        let actionItems = self.actionItems.map { aiItem in
            ActionItem(
                task: aiItem.task,
                assignee: aiItem.assignee?.isEmpty == false ? aiItem.assignee : nil,
                dueDate: parseDueDate(aiItem.dueDate),
                sourceTimestamp: aiItem.timestamp,
                completed: false
            )
        }
        
        return MeetingAnalysis(
            id: id,
            meetingId: meetingId,
            transcriptId: transcriptId,
            overview: overview,
            keyPoints: keyPoints,
            decisions: decisions,
            actionItems: actionItems,
            mom: mom,
            status: .completed,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Date Parsing
    
    private func parseDueDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else {
            return nil
        }
        
        // Try ISO8601 first
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try common date formats
        let dateFormatters = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy",
            "MMM dd, yyyy",
            "MMMM dd, yyyy"
        ]
        
        for formatString in dateFormatters {
            let formatter = DateFormatter()
            formatter.dateFormat = formatString
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Could not parse - return nil
        return nil
    }
}
