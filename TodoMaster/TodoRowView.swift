//
//  TodoRowView.swift
//  TodoMaster
//

import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let now: Date
    let onToggle: () -> Void

    private var isOverdue: Bool {
        DueDate.isOverdue(todo, now: now)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isDone ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isDone ? "Als offen markieren" : "Als erledigt markieren")

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .strikethrough(todo.isDone)
                    .foregroundStyle(todo.isDone ? .secondary : .primary)
                    .lineLimit(3)

                if todo.kind == .extended, !todo.details.isEmpty {
                    Text(todo.details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                metadata
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .opacity(todo.isDone ? 0.55 : 1)
    }

    @ViewBuilder
    private var metadata: some View {
        let imageCount = todo.attachments.filter { $0.kind == .image }.count
        let videoCount = todo.attachments.filter { $0.kind == .video }.count
        let hasMetadata = todo.priority != nil || todo.dueDate != nil || imageCount > 0 || videoCount > 0

        if hasMetadata {
            HStack(spacing: 10) {
                if let priority = todo.priority, let level = todo.priorityLevel {
                    Text("Prio \(PriorityLevel.format(priority))")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PriorityLevel.color(for: level).opacity(0.2), in: Capsule())
                        .foregroundStyle(PriorityLevel.color(for: level))
                }
                if let dueDate = todo.dueDate {
                    HStack(spacing: 3) {
                        Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "calendar")
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    .font(.caption.weight(isOverdue ? .semibold : .regular))
                    .foregroundStyle(isOverdue ? Color.red : Color.secondary)
                    .accessibilityLabel(isOverdue ? "Fällig seit \(dueDate.formatted())" : "Fällig \(dueDate.formatted())")
                }
                if imageCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "photo")
                        Text("\(imageCount)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                if videoCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "video")
                        Text("\(videoCount)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}
