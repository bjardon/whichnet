import AppKit
import SwiftUI

private enum RowStatus {
    case active
    case standby
    case inactive
    case offline

    var label: String {
        switch self {
        case .active: "Active"
        case .standby: "Standby"
        case .inactive: "Inactive"
        case .offline: "Offline"
        }
    }

    var iconColor: Color {
        switch self {
        case .active: Self.activeGreen
        case .standby: Self.standbyBlue
        case .inactive, .offline: Color.primary.opacity(0.28)
        }
    }

    var badgeForeground: Color {
        switch self {
        case .active: Self.activeGreen
        case .standby: Self.standbyBlue
        case .inactive, .offline: .secondary
        }
    }

    var badgeBackground: Color {
        switch self {
        case .active: Self.activeGreen.opacity(0.16)
        case .standby: Self.standbyBlue.opacity(0.16)
        case .inactive, .offline: Color.primary.opacity(0.08)
        }
    }

    private static let activeGreen = Color(nsColor: .systemGreen)
    private static let standbyBlue = Color(nsColor: .systemBlue)
}

struct PanelView: View {
    @ObservedObject var store: NetworkStore
    @State private var launchAtLoginEnabled = false
    @State private var launchAtLoginNote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            VStack(alignment: .leading, spacing: 14) {
                if store.rows.isEmpty {
                    Text(store.snapshot.hasInternet ? "No interfaces reported" : "No internet connection")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.rows) { iface in
                        InterfaceRow(
                            iface: iface,
                            isPrimary: iface.id == store.snapshot.primary?.id,
                            hasInternet: store.snapshot.hasInternet
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()
            footer
        }
        .frame(width: 320)
        .onAppear {
            launchAtLoginEnabled = LaunchAtLogin.isEnabled
            launchAtLoginNote = LaunchAtLogin.lastError
            store.requestSSIDAccess()
        }
    }

    private var header: some View {
        Text("whichnet")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            if LaunchAtLogin.needsApproval {
                Text("Approve WhichNet in System Settings → General → Login Items.")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            if let launchAtLoginNote {
                Text(launchAtLoginNote)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginEnabled },
            set: { newValue in
                launchAtLoginEnabled = newValue
                if let error = LaunchAtLogin.setEnabled(newValue) {
                    launchAtLoginEnabled = LaunchAtLogin.isEnabled
                    launchAtLoginNote = error
                } else {
                    launchAtLoginEnabled = LaunchAtLogin.isEnabled
                    launchAtLoginNote = nil
                }
            }
        )
    }
}

private struct InterfaceRow: View {
    let iface: InterfaceInfo
    let isPrimary: Bool
    let hasInternet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: iface.kind.symbolName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(status.iconColor)
                    .frame(width: 16, height: 16)
                Text(iface.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iface.isLinkActive || isPrimary ? .primary : .secondary)
                Spacer()
                Text(status.label)
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(status.badgeBackground))
                    .foregroundStyle(status.badgeForeground)
            }

            if iface.displayName != iface.kind.title {
                Fact(label: "Type", value: iface.kind.title)
            }
            if let ssid = iface.ssid {
                Fact(label: "Network", value: ssid)
            }
            if let channel = iface.channel {
                Fact(label: "Channel", value: channel)
            }
            if let address = iface.address {
                Fact(label: "Address", value: address)
            }
            Fact(label: "Interface", value: iface.bsdName)
        }
        .opacity(iface.isLinkActive || isPrimary ? 1 : 0.72)
    }

    private var status: RowStatus {
        if isPrimary, hasInternet { return .active }
        if isPrimary { return .offline }
        if iface.isLinkActive { return .standby }
        return .inactive
    }
}

private struct Fact: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }
}
