import SwiftUI

extension LinkKind {
    var accent: Color {
        switch self {
        case .wifi: Color(red: 0.35, green: 0.62, blue: 0.98)
        case .ethernet: Color(red: 0.22, green: 0.78, blue: 0.72)
        case .cellular: Color(red: 0.98, green: 0.62, blue: 0.28)
        case .vpn: Color(red: 0.70, green: 0.45, blue: 0.95)
        case .other: Color(red: 0.55, green: 0.55, blue: 0.60)
        case .offline: Color(red: 0.93, green: 0.35, blue: 0.32)
        }
    }
}

struct PanelView: View {
    @ObservedObject var store: NetworkStore

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
    }

    private var header: some View {
        Text("whichnet")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

private struct InterfaceRow: View {
    let iface: InterfaceInfo
    let isPrimary: Bool
    let hasInternet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(iface.kind.accent).frame(width: 7, height: 7)
                Text(iface.displayName)
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(badge)
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                    .foregroundStyle(.secondary)
            }

            if iface.displayName != iface.kind.title {
                Fact(label: "Type", value: iface.kind.title)
            }
            if let address = iface.address {
                Fact(label: "Address", value: address)
            }
            Fact(label: "Interface", value: iface.bsdName)
        }
    }

    private var badge: String {
        if isPrimary, hasInternet { return "Active" }
        if isPrimary { return "Offline" }
        return "Standby"
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
