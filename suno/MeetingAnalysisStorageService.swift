//
//  MeetingAnalysisStorageService.swift
//  suno
//

import Foundation

class MeetingAnalysisStorageService {
    static let shared = MeetingAnalysisStorageService()
    
    private let fileManager = FileManager.default
    
    // MARK: - Directory Management
    
    private var analysisDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let sunoDir = appSupport.appendingPathComponent("suno")
        let analysisDir = sunoDir.appendingPathComponent("Analysis")
        
        if !fileManager.fileExists(atPath: analysisDir.path) {
            try? fileManager.createDirectory(at: analysisDir, withIntermediateDirectories: true)
        }
        
        return analysisDir
    }
    
    private func analysisFileURL(for transcriptID: UUID) -> URL {
        return analysisDirectory.appendingPathComponent("\(transcriptID.uuidString)-analysis.json")
    }
    
    // MARK: - Save & Load
    
    func saveAnalysis(_ analysis: MeetingAnalysis) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(analysis)
        let url = analysisFileURL(for: analysis.transcriptId)
        try data.write(to: url)
        
        print("💾 Saved analysis for transcript: \(analysis.transcriptId)")
    }
    
    func loadAnalysis(for transcriptID: UUID) throws -> MeetingAnalysis? {
        let url = analysisFileURL(for: transcriptID)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(MeetingAnalysis.self, from: data)
    }
    
    func deleteAnalysis(for transcriptID: UUID) throws {
        let url = analysisFileURL(for: transcriptID)
        
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            print("🗑️ Deleted analysis for transcript: \(transcriptID)")
        }
    }
    
    func analysisExists(for transcriptID: UUID) -> Bool {
        let url = analysisFileURL(for: transcriptID)
        return fileManager.fileExists(atPath: url.path)
    }
    
    // MARK: - Batch Operations
    
    func loadAllAnalyses() throws -> [MeetingAnalysis] {
        let urls = try fileManager.contentsOfDirectory(
            at: analysisDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        return try urls.compactMap { url in
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(MeetingAnalysis.self, from: data)
        }
    }
    
    // MARK: - Action Item Updates
    
    func updateActionItem(_ actionItem: ActionItem, in analysis: MeetingAnalysis) throws {
        var updatedAnalysis = analysis
        
        if let index = updatedAnalysis.actionItems.firstIndex(where: { $0.id == actionItem.id }) {
            updatedAnalysis.actionItems[index] = actionItem
            updatedAnalysis.updatedAt = Date()
            try saveAnalysis(updatedAnalysis)
        }
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
