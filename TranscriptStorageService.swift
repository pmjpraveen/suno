//
//  TranscriptStorageService.swift
//  suno
//

import Foundation

class TranscriptStorageService {
    static let shared = TranscriptStorageService()

    private let store = JSONFileStore<Transcript>(subdirectory: "Transcripts")

    func saveTranscript(_ transcript: Transcript) throws {
        try store.save(transcript, id: transcript.recordingID, suffix: "-transcript")
        print("💾 Saved transcript for recording: \(transcript.recordingID)")
    }

    func loadTranscript(for recordingID: UUID) throws -> Transcript? {
        try store.load(id: recordingID, suffix: "-transcript")
    }

    func deleteTranscript(for recordingID: UUID) throws {
        try store.delete(id: recordingID, suffix: "-transcript")
        print("🗑️ Deleted transcript for recording: \(recordingID)")
    }

    func loadAllTranscripts() throws -> [Transcript] {
        try store.loadAll()
    }
}
