//
//  TodoMasterApp.swift
//  TodoMaster
//

import SwiftData
import SwiftUI
import UserNotifications

@main
struct TodoMasterApp: App {
    @AppStorage("appAppearance") private var appearanceRaw = "system"
    @Environment(\.scenePhase) private var scenePhase

    private var preferredScheme: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
        #if DEBUG
        DemoData.seedIfRequested()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            TodoListView()
                .preferredColorScheme(preferredScheme)
                .dismissesKeyboardOnTapOutside()
        }
        .modelContainer(TodoStore.container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                NotificationScheduler.sync(in: TodoStore.container.mainContext)
            }
        }
    }
}
