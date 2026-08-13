import AppKit
import SwiftUI

@main
struct WhichNetApp: App {
    @StateObject private var store = NetworkStore()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
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
