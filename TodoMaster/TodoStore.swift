//
//  TodoStore.swift
//  TodoMaster
//

import SwiftData

/// App und Siri-Intent nutzen denselben Container, damit Einträge von Siri sofort in der Liste stehen.
enum TodoStore {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Todo.self, MediaAttachment.self)
        } catch {
            fatalError("SwiftData-Container konnte nicht geöffnet werden: \(error)")
        }
    }()

    static func delete(_ todo: Todo, in context: ModelContext) {
        for attachment in todo.attachments {
            MediaStore.delete(fileName: attachment.fileName)
        }
        context.delete(todo)
    }
}
