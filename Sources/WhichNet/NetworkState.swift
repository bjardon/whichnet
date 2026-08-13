import Darwin
import Foundation
import Network
import SystemConfiguration

enum LinkKind: String, Equatable, Sendable {
    case wifi
    case ethernet
    case cellular
    case vpn
    case other
    case offline

    var symbolName: String {
        switch self {
        case .wifi: "wifi"
        case .ethernet: "cable.connector"
        case .cellular: "antenna.radiowaves.left.and.right"
        case .vpn: "lock.shield"
        case .other: "network"
        case .offline: "wifi.slash"
        }
    }

    var title: String {
        switch self {
        case .wifi: "Wi-Fi"
        case .ethernet: "Ethernet"
        case .cellular: "Cellular"
        case .vpn: "VPN"
        case .other: "Other"
        case .offline: "Offline"
        }
    }
}

struct InterfaceInfo: Equatable, Sendable, Identifiable {
    var id: String { bsdName }
    var bsdName: String
    var displayName: String
    var kind: LinkKind
    var address: String?
}

struct NetworkSnapshot: Equatable, Sendable {
    var hasInternet: Bool
    var kind: LinkKind
    var primary: InterfaceInfo?
    var alsoConnected: [InterfaceInfo]

    var tooltip: String {
        guard hasInternet, let primary else { return "No internet connection" }
        let active = primary.displayName == kind.title ? kind.title : "\(kind.title) · \(primary.displayName)"
        if alsoConnected.isEmpty {
            return active
        }
        let others = alsoConnected.map(\.displayName).joined(separator: ", ")
        return "\(active) (\(others) also connected)"
    }
}

enum NetworkProbe {
    static func snapshot(path: NWPath) -> NetworkSnapshot {
        let hasInternet = path.status == .satisfied
        let names = scNames()
        let addrs = interfaceAddresses()
        let primaryName = primaryBSDName() ?? path.availableInterfaces.first?.name

        let primary: InterfaceInfo? = primaryName.map { bsd in
            describe(bsd: bsd, names: names, addrs: addrs, path: path, isPrimary: true)
        }

        var kind: LinkKind = .offline
        if hasInternet {
            kind = primary?.kind ?? kindFromPath(path) ?? .other
        }

        var also: [InterfaceInfo] = []
        for bsd in addrs.keys.sorted() {
            if bsd == primaryName { continue }
            if shouldIgnore(bsd) { continue }
            let info = describe(bsd: bsd, names: names, addrs: addrs, path: path, isPrimary: false)
            guard info.kind == .wifi || info.kind == .ethernet || info.kind == .cellular else { continue }
            guard info.address != nil else { continue }
            also.append(info)
        }

        return NetworkSnapshot(
            hasInternet: hasInternet,
            kind: kind,
            primary: primary,
            alsoConnected: also
        )
    }

    private static func describe(
        bsd: String,
        names: [String: (display: String, type: String)],
        addrs: [String: String],
        path: NWPath,
        isPrimary: Bool
    ) -> InterfaceInfo {
        let sc = names[bsd]
        let kind = classify(bsd: bsd, scType: sc?.type, path: isPrimary ? path : nil)
        let display = sc?.display ?? fallbackDisplay(bsd: bsd, kind: kind)
        return InterfaceInfo(
            bsdName: bsd,
            displayName: display,
            kind: kind,
            address: addrs[bsd]
        )
    }

    private static func classify(bsd: String, scType: String?, path: NWPath?) -> LinkKind {
        if bsd.hasPrefix("utun") || bsd.hasPrefix("ipsec") || bsd.hasPrefix("ppp") {
            return .vpn
        }
        switch scType {
        case "IEEE80211": return .wifi
        case "Ethernet", "Thunderbolt": return .ethernet
        case "WWAN": return .cellular
        default: break
        }
        if let path, let fromPath = kindFromPath(path) {
            return fromPath
        }
        return .other
    }

    private static func kindFromPath(_ path: NWPath) -> LinkKind? {
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.other) { return .other }
        return nil
    }

    private static func fallbackDisplay(bsd: String, kind: LinkKind) -> String {
        switch kind {
        case .wifi: "Wi-Fi"
        case .ethernet: "Ethernet"
        case .cellular: "Cellular"
        case .vpn: "VPN"
        case .offline, .other: bsd
        }
    }

    private static func shouldIgnore(_ bsd: String) -> Bool {
        let prefixes = ["lo", "gif", "stf", "anpi", "ap", "awdl", "llw", "bridge", "debug", "utun", "ipsec"]
        return prefixes.contains { bsd == $0 || bsd.hasPrefix($0) }
    }

    private static func primaryBSDName() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "WhichNet" as CFString, nil, nil) else {
            return nil
        }
        for key in ["State:/Network/Global/IPv4", "State:/Network/Global/IPv6"] {
            if let info = SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any],
               let name = info["PrimaryInterface"] as? String
            {
                return name
            }
        }
        return nil
    }

    private static func scNames() -> [String: (display: String, type: String)] {
        var result: [String: (display: String, type: String)] = [:]
        guard let list = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else {
            return result
        }
        for iface in list {
            guard let bsd = SCNetworkInterfaceGetBSDName(iface) as String? else { continue }
            let display = SCNetworkInterfaceGetLocalizedDisplayName(iface) as String? ?? bsd
            let type = SCNetworkInterfaceGetInterfaceType(iface) as String? ?? ""
            result[bsd] = (display, type)
        }
        return result
    }

    private static func interfaceAddresses() -> [String: String] {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [:] }
        defer { freeifaddrs(ifaddr) }

        var ipv4: [String: String] = [:]
        var ipv6: [String: String] = [:]
        var ptr = ifaddr
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)
            if let ip = numericAddress(current.pointee.ifa_addr, family: AF_INET) {
                ipv4[name] = ip
            } else if let ip = numericAddress(current.pointee.ifa_addr, family: AF_INET6),
                      !ip.hasPrefix("fe80")
            {
                if ipv6[name] == nil { ipv6[name] = ip }
            }
            ptr = current.pointee.ifa_next
        }

        var merged = ipv6
        for (name, ip) in ipv4 {
            merged[name] = ip
        }
        return merged
    }

    private static func numericAddress(_ addr: UnsafeMutablePointer<sockaddr>?, family: Int32) -> String? {
        guard let addr, Int32(addr.pointee.sa_family) == family else { return nil }
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let len = socklen_t(addr.pointee.sa_len)
        guard getnameinfo(addr, len, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else {
            return nil
        }
        let bytes = host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }
}
