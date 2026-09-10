//
//  RecordingStorageService.swift
//  suno
//
//  Created by Praveenkumar Jogannavar on 01/09/26.
//

import Foundation

class RecordingStorageService {
    static let shared = RecordingStorageService()
    
    private let fileManager = FileManager.default
    private let recordingsFileName = "recordings.json"
    
    // MARK: - Directory Management
    
    private var applicationSupportDirectory: URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = urls[0].appendingPathComponent("suno")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: appSupportDir.path) {
            try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        }
        
        return appSupportDir
    }
    
    var recordingsDirectory: URL {
        let dir = applicationSupportDirectory.appendingPathComponent("Recordings")
        
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        
        return dir
    }
    
    private var metadataDirectory: URL {
        let dir = applicationSupportDirectory.appendingPathComponent("Metadata")
        
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        
        return dir
    }
    
    private var metadataFileURL: URL {
        return metadataDirectory.appendingPathComponent(recordingsFileName)
    }
    
    // MARK: - Audio File Management
    
    func createAudioFileURL(format: AudioFormat) -> URL {
        let fileName = "\(UUID().uuidString).\(format.fileExtension)"
        return recordingsDirectory.appendingPathComponent(fileName)
    }

    /// Companion file for the same recording's captured system audio.
    func systemAudioFileURL(for micFileURL: URL) -> URL {
        micFileURL.deletingPathExtension().appendingPathExtension("system.caf")
    }
    
    func getFileSize(at url: URL) -> Int64 {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }
        return fileSize
    }
    
    func deleteAudioFile(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    // MARK: - Metadata Persistence
    
    func saveRecordings(_ recordings: [Recording]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(recordings)
        try data.write(to: metadataFileURL)
    }
    
    func loadRecordings() throws -> [Recording] {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: metadataFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([Recording].self, from: data)
    }
    
    // MARK: - Recording Management
    
    func addRecording(_ recording: Recording, to recordings: inout [Recording]) throws {
        recordings.append(recording)
        try saveRecordings(recordings)
    }
    
    func deleteRecording(_ recording: Recording, from recordings: inout [Recording]) throws {
        // Delete audio file
        if fileManager.fileExists(atPath: recording.fileURL.path) {
            try deleteAudioFile(at: recording.fileURL)
        }

        // Delete companion system-audio file, if this recording captured one
        if let systemAudioURL = recording.systemAudioFileURL, fileManager.fileExists(atPath: systemAudioURL.path) {
            try? deleteAudioFile(at: systemAudioURL)
        }

        // Delete associated transcript file if it exists
        let transcriptURL = applicationSupportDirectory
            .appendingPathComponent("Transcripts")
            .appendingPathComponent("\(recording.id).json")
        if fileManager.fileExists(atPath: transcriptURL.path) {
            try? fileManager.removeItem(at: transcriptURL)
        }
        
        // Delete associated analysis file if it exists
        let analysisURL = applicationSupportDirectory
            .appendingPathComponent("Analysis")
            .appendingPathComponent("\(recording.id).json")
        if fileManager.fileExists(atPath: analysisURL.path) {
            try? fileManager.removeItem(at: analysisURL)
        }
        
        // Remove from array
        recordings.removeAll { $0.id == recording.id }
        
        // Save updated metadata
        try saveRecordings(recordings)
    }
    
    func updateRecording(_ recording: Recording, in recordings: inout [Recording]) throws {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
            try saveRecordings(recordings)
        }
    }
}
