//
//  NotificationScheduler.swift
//  TodoMaster
//

import Foundation
import SwiftData
import UserNotifications

/// Lokale Mitteilungen zur Fälligkeit. Nach jeder Änderung wird der komplette Bestand neu abgeglichen,
/// damit erledigte, gelöschte oder umdatierte Todos keine alte Mitteilung behalten.
enum NotificationScheduler {
    /// iOS behält höchstens 64 geplante Mitteilungen pro App.
    private static let maxPending = 60
    private static let identifierPrefix = "todo-due-"

    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    private struct Reminder: Sendable {
        let identifier: String
        let title: String
        let body: String
        let dueDate: Date
    }

    @MainActor
    static func sync(in context: ModelContext) {
        let todos = (try? context.fetch(FetchDescriptor<Todo>())) ?? []
        let now = Date.now
        let reminders: [Reminder] = todos
            .compactMap { todo in
                guard !todo.isDone, let dueDate = todo.dueDate, dueDate > now else { return nil }
                return Reminder(
                    identifier: identifier(for: todo),
                    title: todo.title,
                    body: todo.details.isEmpty ? "Jetzt fällig." : todo.details,
                    dueDate: dueDate
                )
            }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(maxPending)
            .map { $0 }

        Task.detached {
            let center = UNUserNotificationCenter.current()
            let stale = await center.pendingNotificationRequests()
                .map(\.identifier)
                .filter { $0.hasPrefix(identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: stale)
            for reminder in reminders {
                try? await center.add(makeRequest(for: reminder))
            }
        }
    }

    private static func makeRequest(for reminder: Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
    }

    private static func identifier(for todo: Todo) -> String {
        "\(identifierPrefix)\(Int(todo.createdAt.timeIntervalSince1970 * 1000))"
    }
}

/// Zeigt Mitteilungen auch dann als Banner, wenn die App gerade offen ist.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
