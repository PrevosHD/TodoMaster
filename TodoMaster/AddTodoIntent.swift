//
//  AddTodoIntent.swift
//  TodoMaster
//

import AppIntents
import SwiftData

struct AddTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "Neue Todo"
    static let description = IntentDescription("Legt eine ExpressTodo ohne Priorität und ohne Datum an.")
    static let openAppWhenRun = false

    @Parameter(title: "Titel", requestValueDialog: "Wie lautet der Titel?")
    var todoTitle: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = todoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw $todoTitle.needsValueError("Wie lautet der Titel?")
        }
        let context = TodoStore.container.mainContext
        context.insert(Todo(kind: .express, title: trimmed))
        try context.save()
        return .result(dialog: "„\(trimmed)“ steht in TodoMaster.")
    }
}

struct TodoMasterShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTodoIntent(),
            phrases: [
                "Neue \(.applicationName)",
                "Neuer \(.applicationName)",
                "Neues \(.applicationName)",
                "\(.applicationName) neue Todo",
                "Neue Todo in \(.applicationName)",
                "Neues To-do in \(.applicationName)",
                "Neue Aufgabe in \(.applicationName)",
                "Neuer Eintrag in \(.applicationName)",
                "Eintrag in \(.applicationName)",
            ],
            shortTitle: "Neue Todo",
            systemImageName: "plus.circle"
        )
    }
}
