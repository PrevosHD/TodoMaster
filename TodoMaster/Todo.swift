//
//  Todo.swift
//  TodoMaster
//

import Foundation
import SwiftData

enum TodoKind: String, Codable {
    case express
    case extended
}

@Model
final class Todo {
    var kindRaw: String = TodoKind.express.rawValue
    var title: String = ""
    var details: String = ""
    /// 1 ist am wichtigsten, 5 am unwichtigsten. `nil` heißt keine Priorität.
    var priority: Double?
    var dueDate: Date?
    var isDone: Bool = false
    var createdAt: Date = Date.now
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \MediaAttachment.todo)
    var attachments: [MediaAttachment] = []

    init(
        kind: TodoKind,
        title: String,
        details: String = "",
        priority: Double? = nil,
        dueDate: Date? = nil
    ) {
        self.kindRaw = kind.rawValue
        self.title = title
        self.details = details
        self.priority = priority
        self.dueDate = dueDate
        self.createdAt = .now
    }

    var kind: TodoKind {
        get { TodoKind(rawValue: kindRaw) ?? .express }
        set { kindRaw = newValue.rawValue }
    }

    var priorityLevel: Int? {
        priority.map(PriorityLevel.bucket)
    }

    var sortedAttachments: [MediaAttachment] {
        attachments.sorted { $0.order < $1.order }
    }
}

enum MediaKind: String, Codable {
    case image
    case video
}

@Model
final class MediaAttachment {
    var fileName: String = ""
    var kindRaw: String = MediaKind.image.rawValue
    var order: Int = 0
    var todo: Todo?

    init(fileName: String, kind: MediaKind, order: Int) {
        self.fileName = fileName
        self.kindRaw = kind.rawValue
        self.order = order
    }

    var kind: MediaKind {
        MediaKind(rawValue: kindRaw) ?? .image
    }

    var fileURL: URL {
        MediaStore.url(for: fileName)
    }
}
