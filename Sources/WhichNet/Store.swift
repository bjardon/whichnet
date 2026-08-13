import Network
import SwiftUI

@MainActor
final class NetworkStore: ObservableObject {
    @Published private(set) var snapshot = NetworkSnapshot(
        hasInternet: false,
        kind: .offline,
        primary: nil,
        alsoConnected: []
    )
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefresh: Date?
    @Published private(set) var tick = Date()

    private var monitor: NWPathMonitor?
    private var started = false
    private var loop: Task<Void, Never>?

    init() {
        start()
    }

    var rows: [InterfaceInfo] {
        if let primary = snapshot.primary {
            return [primary] + snapshot.alsoConnected
        }
        return snapshot.alsoConnected
    }

    func start() {
        guard !started else { return }
        started = true
        NetworkStore.shared = self

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            let next = NetworkProbe.snapshot(path: path)
            Task { @MainActor in
                NetworkStore.shared?.apply(next)
            }
        }
        monitor.start(queue: DispatchQueue(label: "dev.bjardon.whichnet.path"))
        self.monitor = monitor

        loop = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self.tick = Date()
                if Int(self.tick.timeIntervalSince1970).isMultiple(of: 2) {
                    self.refresh(showSpinner: false)
                }
            }
        }

        refresh(showSpinner: false)
    }

    func refresh(showSpinner: Bool = true) {
        if showSpinner { isRefreshing = true }
        defer { if showSpinner { isRefreshing = false } }
        guard let path = monitor?.currentPath else { return }
        apply(NetworkProbe.snapshot(path: path))
    }

    fileprivate func apply(_ next: NetworkSnapshot) {
        lastRefresh = Date()
        if snapshot != next {
            snapshot = next
        }
    }

    deinit {
        loop?.cancel()
        monitor?.cancel()
    }
}

extension NetworkStore {
    static weak var shared: NetworkStore?
}
