import AppKit
import SwiftUI

@main
struct WhichNetApp: App {
    @StateObject private var store = NetworkStore()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        // SMAppService needs Launch Services to know about this bundle; App.init is too early.
        DispatchQueue.main.async {
            LaunchAtLogin.applyDefaultIfNeeded()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PanelView(store: store)
        } label: {
            let _ = store.snapshot
            Image(systemName: store.snapshot.kind.symbolName)
        }
        .menuBarExtraStyle(.window)
    }
}
