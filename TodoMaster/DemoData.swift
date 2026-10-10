//
//  DemoData.swift
//  TodoMaster
//

#if DEBUG
import Foundation
import SwiftData

/// Beispiel-Todos für Screenshots. Nur in Debug-Builds und nur mit dem Startargument `-demoData`.
enum DemoData {
    @MainActor
    static func seedIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-demoData") else { return }
        let context = TodoStore.container.mainContext
        let existing = (try? context.fetchCount(FetchDescriptor<Todo>())) ?? 0
        guard existing == 0 else { return }

        let calendar = Calendar.current
        func day(_ offset: Int) -> Date {
            calendar.startOfDay(for: calendar.date(byAdding: .day, value: offset, to: .now)!)
        }
        func ago(minutes: Int) -> Date {
            Date.now.addingTimeInterval(TimeInterval(-minutes * 60))
        }

        let samples: [(TodoKind, String, String, Double?, Date?, Bool, Int)] = [
            (.extended, "Steuererklärung abgeben", "Belege im Ordner sammeln\nhttps://www.elster.de", 1, day(2), false, 5),
            (.express, "Zahnarzttermin vereinbaren", "", 1.75, day(1), false, 12),
            (.extended, "Urlaub Gardasee planen", "Unterkünfte vergleichen, Fähre checken\nhttps://www.booking.com", 2.25, day(14), false, 30),
            (.express, "Reifenwechsel Auto", "", 3, day(6), false, 45),
            (.express, "Geschenk für Mama", "", nil, day(9), false, 60),
            (.extended, "Rezept Lasagne ausprobieren", "Video aus dem Chat gespeichert", 4.5, nil, false, 90),
            (.express, "Pakete zur Post bringen", "", 2, day(-1), false, 120),
            (.express, "Wohnung kündigen", "", 1, nil, true, 200),
            (.express, "Fahrrad aufpumpen", "", 5, nil, true, 300),
        ]

        for (kind, title, details, priority, due, done, minutes) in samples {
            let todo = Todo(kind: kind, title: title, details: details, priority: priority, dueDate: due)
            todo.createdAt = ago(minutes: minutes)
            todo.isDone = done
            todo.completedAt = done ? ago(minutes: minutes - 10) : nil
            context.insert(todo)
        }
        try? context.save()
    }
}
#endif
