//
//  TodoRowView.swift
//  TodoMaster
//

import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let onToggle: () -> Void

    private var isOverdue: Bool {
        guard let dueDate = todo.dueDate, !todo.isDone else { return false }
        return Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: .now)
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
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(isOverdue ? Color.red : Color.secondary)
                }
                if imageCount > 0 {
                    Label("\(imageCount)", systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if videoCount > 0 {
                    Label("\(videoCount)", systemImage: "video")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
