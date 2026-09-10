//
//  JSONFileStore.swift
//  suno
//

import Foundation

/// Generic per-record JSON file store under Application Support/suno/<subdirectory>.
final class JSONFileStore<T: Codable> {
    private let fileManager = FileManager.default
    private let directory: URL

    init(subdirectory: String) {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = appSupport.appendingPathComponent("suno").appendingPathComponent(subdirectory)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private func fileURL(for id: UUID, suffix: String) -> URL {
        directory.appendingPathComponent("\(id.uuidString)\(suffix).json")
    }

    func save(_ value: T, id: UUID, suffix: String = "") throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        try encoder.encode(value).write(to: fileURL(for: id, suffix: suffix))
    }

    func load(id: UUID, suffix: String = "") throws -> T? {
        let url = fileURL(for: id, suffix: suffix)
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    func delete(id: UUID, suffix: String = "") throws {
        let url = fileURL(for: id, suffix: suffix)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func loadAll() throws -> [T] {
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try urls.compactMap { url in
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        }
    }
}
