//
//  TodoEditorView.swift
//  TodoMaster
//

import PhotosUI
import SwiftData
import SwiftUI

struct TodoEditorView: View {
    let todo: Todo?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var kind: TodoKind
    @State private var title: String
    @State private var details: String
    @State private var priority: Double?
    @State private var dueDate: Date?
    @State private var media: [DraftMedia]
    @State private var removedMedia: [DraftMedia] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var viewedMedia: DraftMedia?
    @FocusState private var titleFocused: Bool

    init(todo: Todo?, initialKind: TodoKind) {
        self.todo = todo
        _kind = State(initialValue: todo?.kind ?? initialKind)
        _title = State(initialValue: todo?.title ?? "")
        _details = State(initialValue: todo?.details ?? "")
        _priority = State(initialValue: todo?.priority)
        _dueDate = State(initialValue: todo?.dueDate)
        _media = State(initialValue: (todo?.sortedAttachments ?? []).map {
            DraftMedia(fileName: $0.fileName, kind: $0.kind, isExisting: true)
        })
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var navigationTitle: String {
        switch (todo == nil, kind) {
        case (true, .express): return "ExpressTodo"
        case (true, .extended): return "ExtendedTodo"
        case (false, _): return "Bearbeiten"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if kind == .express {
                    expressSection
                } else {
                    extendedSections
                }

                Section("Priorität") {
                    PrioritySlider(priority: $priority)
                        .padding(.vertical, 4)
                }

                dueDateSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        cancel()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Abbrechen")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                    }
                    .disabled(trimmedTitle.isEmpty || isImporting)
                    .accessibilityLabel("Speichern")
                }
            }
            .onAppear {
                if todo == nil { titleFocused = true }
            }
            .onChange(of: pickerItems) { _, items in
                importPicked(items)
            }
            .sheet(item: $viewedMedia) { item in
                MediaViewer(media: item)
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }

    private var expressSection: some View {
        Section {
            TextField("Was ist zu tun?", text: $title, axis: .vertical)
                .focused($titleFocused)
            Button {
                kind = .extended
            } label: {
                Label("Erweitern", systemImage: "arrow.up.left.and.arrow.down.right")
            }
        }
    }

    @ViewBuilder
    private var extendedSections: some View {
        Section("Titel") {
            TextField("Titel", text: $title, axis: .vertical)
                .focused($titleFocused)
        }

        Section("Details") {
            TextField("Genauere Infos, zum Beispiel Links", text: $details, axis: .vertical)
                .lineLimit(4...12)
            ForEach(LinkDetector.links(in: details), id: \.self) { url in
                Link(destination: url) {
                    Label(url.absoluteString, systemImage: "link")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }

        Section("Medien") {
            if !media.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    ForEach(media) { item in
                        MediaThumbnail(url: item.fileURL, kind: item.kind)
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    remove(item)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                                .accessibilityLabel("Medium entfernen")
                            }
                            .onTapGesture { viewedMedia = item }
                    }
                }
                .padding(.vertical, 4)
            }

            PhotosPicker(
                selection: $pickerItems,
                matching: .any(of: [.images, .videos])
            ) {
                HStack {
                    Label("Fotos oder Videos hinzufügen", systemImage: "photo.on.rectangle.angled")
                    if isImporting {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isImporting)
        }
    }

    private var dueDateSection: some View {
        Section {
            Toggle("Datum und Uhrzeit festlegen", isOn: Binding(
                get: { dueDate != nil },
                set: { isOn in
                    dueDate = isOn ? (dueDate ?? DueDate.nextFullHour()) : nil
                    if isOn {
                        Task { await NotificationScheduler.requestAuthorizationIfNeeded() }
                    }
                }
            ))
            if let dueDate {
                DatePicker(
                    "Fällig",
                    selection: Binding(get: { dueDate }, set: { self.dueDate = $0 }),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
            }
        } header: {
            Text("Erledigt bis")
        } footer: {
            if dueDate != nil {
                Text("Zur Fälligkeit kommt eine Mitteilung.")
            }
        }
    }

    private var hasChanges: Bool {
        guard let todo else {
            return !trimmedTitle.isEmpty || !details.isEmpty || priority != nil || dueDate != nil || !media.isEmpty
        }
        return title != todo.title
            || details != todo.details
            || priority != todo.priority
            || dueDate != todo.dueDate
            || kind != todo.kind
            || !removedMedia.isEmpty
            || media.contains { !$0.isExisting }
    }

    private func importPicked(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        isImporting = true
        Task {
            for item in items {
                if let draft = await MediaImporter.importItem(item) {
                    media.append(draft)
                }
            }
            pickerItems = []
            isImporting = false
        }
    }

    private func remove(_ item: DraftMedia) {
        media.removeAll { $0.id == item.id }
        if item.isExisting {
            removedMedia.append(item)
        } else {
            MediaStore.delete(fileName: item.fileName)
        }
    }

    private func cancel() {
        for item in media where !item.isExisting {
            MediaStore.delete(fileName: item.fileName)
        }
        dismiss()
    }

    private func save() {
        guard !trimmedTitle.isEmpty else { return }

        let target: Todo
        if let todo {
            target = todo
        } else {
            target = Todo(kind: kind, title: trimmedTitle)
            modelContext.insert(target)
        }

        target.kind = kind
        target.title = trimmedTitle
        target.details = kind == .extended ? details.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        target.priority = priority
        target.dueDate = dueDate.map(DueDate.truncatedToMinute)

        let removedNames = Set(removedMedia.map(\.fileName))
        for attachment in target.attachments where removedNames.contains(attachment.fileName) {
            modelContext.delete(attachment)
            MediaStore.delete(fileName: attachment.fileName)
        }

        for (index, item) in media.enumerated() {
            if item.isExisting {
                target.attachments.first { $0.fileName == item.fileName }?.order = index
            } else {
                let attachment = MediaAttachment(fileName: item.fileName, kind: item.kind, order: index)
                attachment.todo = target
                modelContext.insert(attachment)
            }
        }

        try? modelContext.save()
        NotificationScheduler.sync(in: modelContext)
        dismiss()
    }
}

enum LinkDetector {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    static func links(in text: String) -> [URL] {
        guard let detector, !text.isEmpty else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        var seen = Set<URL>()
        return detector.matches(in: text, range: range).compactMap(\.url).filter { seen.insert($0).inserted }
    }
}
