//
//  TranscriptStorageService.swift
//  suno
//

import Foundation

class TranscriptStorageService {
    static let shared = TranscriptStorageService()
    
    private let fileManager = FileManager.default
    
    // MARK: - Directory Management
    
    private var transcriptsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let sunoDir = appSupport.appendingPathComponent("suno")
        let transcriptsDir = sunoDir.appendingPathComponent("Transcripts")
        
        if !fileManager.fileExists(atPath: transcriptsDir.path) {
            try? fileManager.createDirectory(at: transcriptsDir, withIntermediateDirectories: true)
        }
        
        return transcriptsDir
    }
    
    private func transcriptFileURL(for recordingID: UUID) -> URL {
        return transcriptsDirectory.appendingPathComponent("\(recordingID.uuidString)-transcript.json")
    }
    
    // MARK: - Save & Load
    
    func saveTranscript(_ transcript: Transcript) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(transcript)
        let url = transcriptFileURL(for: transcript.recordingID)
        try data.write(to: url)
        
        print("💾 Saved transcript for recording: \(transcript.recordingID)")
    }
    
    func loadTranscript(for recordingID: UUID) throws -> Transcript? {
        let url = transcriptFileURL(for: recordingID)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Transcript.self, from: data)
    }
    
    func deleteTranscript(for recordingID: UUID) throws {
        let url = transcriptFileURL(for: recordingID)
        
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            print("🗑️ Deleted transcript for recording: \(recordingID)")
        }
    }
    
    func transcriptExists(for recordingID: UUID) -> Bool {
        let url = transcriptFileURL(for: recordingID)
        return fileManager.fileExists(atPath: url.path)
    }
    
    // MARK: - Batch Operations
    
    func loadAllTranscripts() throws -> [Transcript] {
        let urls = try fileManager.contentsOfDirectory(
            at: transcriptsDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        return try urls.compactMap { url in
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Transcript.self, from: data)
        }
    }
}
