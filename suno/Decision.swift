//
//  Decision.swift
//  suno
//

import Foundation

struct Decision: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    var sourceTimestamp: TimeInterval?  // Timestamp in the recording/transcript
    
    init(
        id: UUID = UUID(),
        text: String,
        sourceTimestamp: TimeInterval? = nil
    ) {
        self.id = id
        self.text = text
        self.sourceTimestamp = sourceTimestamp
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
}
