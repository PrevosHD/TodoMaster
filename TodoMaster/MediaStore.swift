//
//  MediaStore.swift
//  TodoMaster
//

import Foundation

/// Fotos und Videos liegen als Dateien im App-Ordner, nicht in SwiftData.
enum MediaStore {
    static let directory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Media", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    static func save(data: Data, fileExtension: String) throws -> String {
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        try data.write(to: url(for: fileName), options: .atomic)
        return fileName
    }

    static func importFile(at source: URL) throws -> String {
        let ext = source.pathExtension.isEmpty ? "mov" : source.pathExtension
        let fileName = "\(UUID().uuidString).\(ext)"
        try FileManager.default.copyItem(at: source, to: url(for: fileName))
        return fileName
    }

    static func delete(fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
