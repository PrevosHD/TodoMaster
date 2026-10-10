//
//  TodoMasterApp.swift
//  TodoMaster
//

import SwiftData
import SwiftUI

@main
struct TodoMasterApp: App {
    @AppStorage("appAppearance") private var appearanceRaw = "system"

    private var preferredScheme: ColorScheme? {
        switch appearanceRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    init() {
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
    }
}
