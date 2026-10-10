//
//  DueDate.swift
//  TodoMaster
//

import Foundation

enum DueDate {
    static func nextFullHour(after date: Date = .now) -> Date {
        let calendar = Calendar.current
        let hourStart = calendar.dateInterval(of: .hour, for: date)?.start ?? date
        return calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? date
    }

    static func truncatedToMinute(_ date: Date) -> Date {
        Calendar.current.dateInterval(of: .minute, for: date)?.start ?? date
    }

    /// Fällig heißt: offen und der Zeitpunkt ist erreicht.
    static func isOverdue(_ todo: Todo, now: Date) -> Bool {
        guard let dueDate = todo.dueDate, !todo.isDone else { return false }
        return dueDate <= now
    }
}
