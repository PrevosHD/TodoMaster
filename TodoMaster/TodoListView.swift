//
//  TodoListView.swift
//  TodoMaster
//

import SwiftData
import SwiftUI

enum ActiveSheet: Identifiable {
    case new(TodoKind)
    case edit(Todo)
    case settings

    var id: String {
        switch self {
        case .new(let kind): return "new-\(kind.rawValue)"
        case .edit(let todo): return "edit-\(todo.persistentModelID.hashValue)"
        case .settings: return "settings"
        }
    }
}

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var todos: [Todo]

    @AppStorage("todoSort") private var sortRaw = TodoSort.newest.rawValue
    @AppStorage("overdueFirst") private var overdueFirst = true
    @State private var priorityFilter: Int?
    @State private var searchText = ""
    @State private var activeSheet: ActiveSheet?

    private var sort: TodoSort {
        TodoSort(rawValue: sortRaw) ?? .newest
    }

    private func visibleTodos(now: Date) -> [Todo] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = todos.filter { todo in
            if let priorityFilter, todo.priorityLevel != priorityFilter { return false }
            guard !query.isEmpty else { return true }
            if todo.title.localizedStandardContains(query) { return true }
            return todo.kind == .extended && todo.details.localizedStandardContains(query)
        }
        return sort.arrange(filtered, now: now, overdueFirst: overdueFirst)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            list
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .new(let kind):
                TodoEditorView(todo: nil, initialKind: kind)
            case .edit(let todo):
                TodoEditorView(todo: todo, initialKind: todo.kind)
            case .settings:
                SettingsView()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            priorityChips

            HStack {
                Button {
                    activeSheet = .settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                }
                .accessibilityLabel("Einstellungen")
                Spacer()
            }

            HStack(spacing: 10) {
                sortMenu
                searchField
                addMenu
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var priorityChips: some View {
        HStack(spacing: 8) {
            ForEach(PriorityLevel.levels, id: \.self) { level in
                let isActive = priorityFilter == level
                let color = PriorityLevel.color(for: level)
                Button {
                    priorityFilter = isActive ? nil : level
                } label: {
                    Text("Prio \(level)")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isActive ? color : color.opacity(0.15), in: Capsule())
                        .foregroundStyle(isActive ? Color.white : color)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sortieren", selection: $sortRaw) {
                ForEach(TodoSort.allCases) { option in
                    Text(option.label).tag(option.rawValue)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.title3)
        }
        .accessibilityLabel("Sortieren: \(sort.label)")
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Suchen", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Suche löschen")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private var addMenu: some View {
        Menu {
            Button {
                activeSheet = .new(.express)
            } label: {
                Label("ExpressTodo", systemImage: "bolt")
            }
            Button {
                activeSheet = .new(.extended)
            } label: {
                Label("ExtendedTodo", systemImage: "doc.richtext")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
        }
        .accessibilityLabel("Neue Todo")
    }

    /// Jede Minute neu, damit eine Todo zum Fälligkeitszeitpunkt rot wird und nach oben rutscht.
    private var list: some View {
        TimelineView(.everyMinute) { timeline in
            listContent(now: timeline.date)
        }
    }

    @ViewBuilder
    private func listContent(now: Date) -> some View {
        let items = visibleTodos(now: now)
        if items.isEmpty {
            ContentUnavailableView {
                Label(todos.isEmpty ? "Noch keine Todos" : "Nichts gefunden", systemImage: "checklist")
            } description: {
                Text(todos.isEmpty ? "Tippe auf +, um eine Todo anzulegen." : "Ändere Filter oder Suche.")
            }
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(items) { todo in
                    TodoRowView(todo: todo, now: now, onToggle: { toggle(todo) })
                        .contentShape(Rectangle())
                        .onTapGesture { activeSheet = .edit(todo) }
                        .listRowSeparatorTint(Color.secondary.opacity(0.25))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(todo)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.immediately)
            .animation(.default, value: items.map(\.persistentModelID))
        }
    }

    private func toggle(_ todo: Todo) {
        todo.isDone.toggle()
        todo.completedAt = todo.isDone ? .now : nil
        try? modelContext.save()
        NotificationScheduler.sync(in: modelContext)
    }

    private func delete(_ todo: Todo) {
        TodoStore.delete(todo, in: modelContext)
        try? modelContext.save()
        NotificationScheduler.sync(in: modelContext)
    }
}

#Preview {
    TodoListView()
        .modelContainer(for: [Todo.self, MediaAttachment.self], inMemory: true)
}
