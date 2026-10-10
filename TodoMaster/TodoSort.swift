//
//  TodoSort.swift
//  TodoMaster
//

import Foundation

enum TodoSort: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case priorityHigh
    case priorityLow
    case upcoming

    var id: String { rawValue }

    var label: String {
        switch self {
        case .newest: return "Neueste"
        case .oldest: return "Älteste"
        case .priorityHigh: return "Priorität 1 zuerst"
        case .priorityLow: return "Priorität 5 zuerst"
        case .upcoming: return "Bevorstehende"
        }
    }

    /// Optional fällige Todos zuerst (am längsten fällig oben), dann offene in der gewählten Reihenfolge,
    /// erledigte immer darunter.
    func arrange(_ todos: [Todo], now: Date = .now, overdueFirst: Bool = false) -> [Todo] {
        let open = todos.filter { !$0.isDone }
        let overdue = overdueFirst
            ? open.filter { DueDate.isOverdue($0, now: now) }.sorted { $0.dueDate! < $1.dueDate! }
            : []
        let rest = open.filter { !overdueFirst || !DueDate.isOverdue($0, now: now) }.sorted(by: areInOrder)
        let done = todos.filter(\.isDone).sorted {
            ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt)
        }
        return overdue + rest + done
    }

    private func areInOrder(_ a: Todo, _ b: Todo) -> Bool {
        switch self {
        case .newest:
            return a.createdAt > b.createdAt
        case .oldest:
            return a.createdAt < b.createdAt
        case .priorityHigh:
            return Self.compareOptional(a.priority, b.priority, ascending: true) ?? (a.createdAt > b.createdAt)
        case .priorityLow:
            return Self.compareOptional(a.priority, b.priority, ascending: false) ?? (a.createdAt > b.createdAt)
        case .upcoming:
            return Self.compareOptional(a.dueDate, b.dueDate, ascending: true) ?? (a.createdAt > b.createdAt)
        }
    }

    /// Fehlende Werte landen immer hinten. `nil` heißt gleichwertig.
    private static func compareOptional<T: Comparable>(_ a: T?, _ b: T?, ascending: Bool) -> Bool? {
        switch (a, b) {
        case let (a?, b?):
            if a == b { return nil }
            return ascending ? a < b : a > b
        case (.some, .none): return true
        case (.none, .some): return false
        case (.none, .none): return nil
        }
    }
}
