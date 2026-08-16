import AppKit
import CoreLocation
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

    private var monitor: NWPathMonitor?
    private var started = false
    private var loop: Task<Void, Never>?
    private let location = LocationAccess()

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

        location.onChange = { [weak self] in
            self?.refresh()
        }
        location.requestIfNeeded()

        loop = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                self.refresh()
            }
        }

        refresh()
    }

    func requestSSIDAccess() {
        location.requestIfNeeded()
    }

    private func refresh() {
        guard let path = monitor?.currentPath else { return }
        apply(NetworkProbe.snapshot(path: path))
    }

    fileprivate func apply(_ next: NetworkSnapshot) {
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

/// CoreWLAN withholds SSID until Location Services authorizes this bundle.
@MainActor
private final class LocationAccess: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onChange: (() -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            NSApplication.shared.activate(ignoringOtherApps: true)
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            self?.onChange?()
        }
    }
}
