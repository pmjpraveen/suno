//
//  MeetingAnalysisStorageService.swift
//  suno
//

import Foundation

class MeetingAnalysisStorageService {
    static let shared = MeetingAnalysisStorageService()

    private let store = JSONFileStore<MeetingAnalysis>(subdirectory: "Analysis")

    func saveAnalysis(_ analysis: MeetingAnalysis) throws {
        try store.save(analysis, id: analysis.transcriptId, suffix: "-analysis")
        print("💾 Saved analysis for transcript: \(analysis.transcriptId)")
    }

    func loadAnalysis(for transcriptID: UUID) throws -> MeetingAnalysis? {
        try store.load(id: transcriptID, suffix: "-analysis")
    }

    func deleteAnalysis(for transcriptID: UUID) throws {
        try store.delete(id: transcriptID, suffix: "-analysis")
        print("🗑️ Deleted analysis for transcript: \(transcriptID)")
    }

    func loadAllAnalyses() throws -> [MeetingAnalysis] {
        try store.loadAll()
    }

    func toggleActionItemCompletion(_ actionItemId: UUID, in analysis: MeetingAnalysis) throws {
        var updatedAnalysis = analysis

        if let index = updatedAnalysis.actionItems.firstIndex(where: { $0.id == actionItemId }) {
            updatedAnalysis.actionItems[index].completed.toggle()
            updatedAnalysis.updatedAt = Date()
            try saveAnalysis(updatedAnalysis)
        }
    }
}
