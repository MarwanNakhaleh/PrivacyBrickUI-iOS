import Foundation
import Observation

/// In-memory brick used by SwiftUI previews and the `-mockAPI` UI-test run.
/// Pairing code is always 123456. State (toggles, rules) mutates realistically
/// so flows can be exercised end-to-end with no hardware.
final class MockBrickAPI: BrickAPI, @unchecked Sendable {
    static let pairingCode = "123456"

    private var adBlockingOn = true
    private var remoteAccessOn = true
    private var cloudFilteringOn = false
    private var userBlocklists: [Blocklist] = [
        Blocklist(id: 1, name: "AdGuard DNS filter", url: "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt", enabled: true, rulesCount: 48_620),
        Blocklist(id: 2, name: "OISD Basic", url: "https://abp.oisd.nl/basic/", enabled: true, rulesCount: 212_340),
    ]
    private var nextBlocklistID = 3

    func pair(code: String) async throws -> PairingGrant {
        try await Task.sleep(for: .milliseconds(300))
        guard code == Self.pairingCode else {
            throw BrickError.pairingRejected("Wrong or expired code. Get a fresh one from the device.")
        }
        return PairingGrant(token: "mock-token", deviceName: "PrivacyBrick (Demo)")
    }

    func identity() async throws -> BrickIdentity {
        BrickIdentity(
            deviceName: "PrivacyBrick (Demo)", version: "0.1.0", port: 8787,
            lanIP: "192.168.1.42", tailscaleIPs: ["100.101.102.103"],
            magicDNSName: "privacybrick.tailnet-demo.ts.net"
        )
    }

    func overview() async throws -> BrickOverview {
        BrickOverview(
            deviceName: "PrivacyBrick (Demo)",
            protected: adBlockingOn,
            services: [
                ServiceStatus(id: "adguard", name: "Ad Blocking", running: adBlockingOn,
                              installed: true, detail: adBlockingOn ? "protecting" : "paused"),
                ServiceStatus(id: "unbound", name: "Private DNS", running: true,
                              installed: true, detail: "active"),
                ServiceStatus(id: "doh", name: "Encrypted DNS", running: true,
                              installed: true, detail: "active"),
                ServiceStatus(id: "tailscale", name: "Remote Access", running: remoteAccessOn,
                              installed: true, detail: remoteAccessOn ? "Running" : "Stopped"),
                ServiceStatus(id: "nextdns", name: "Cloud Filtering", running: cloudFilteringOn,
                              installed: true, detail: cloudFilteringOn ? "running" : "stopped"),
                ServiceStatus(id: "ntopng", name: "Network Monitor", running: true,
                              installed: true, detail: "active"),
                ServiceStatus(id: "system", name: "Device", running: true,
                              installed: true, detail: "online"),
            ]
        )
    }

    func adBlockStats() async throws -> AdBlockStats {
        AdBlockStats(totalQueries: 48_213, blocked: 9_384, blockedPercent: 19.5)
    }

    func setAdBlocking(enabled: Bool) async throws -> BrickActionResult {
        adBlockingOn = enabled
        return BrickActionResult(ok: true, message: enabled ? "Ad blocking on" : "Ad blocking paused")
    }

    func queryLog(limit: Int, search: String?) async throws -> [QueryLogEntry] {
        let sample: [(String, Bool)] = [
            ("doubleclick.net", true), ("apple.com", false), ("graph.facebook.com", true),
            ("icloud.com", false), ("app-measurement.com", true), ("wikipedia.org", false),
            ("adservice.google.com", true), ("github.com", false), ("branch.io", true),
            ("netflix.com", false), ("crashlytics.com", true), ("signal.org", false),
        ]
        return sample
            .filter { item in
                guard let search, !search.isEmpty else { return true }
                return item.0.contains(search.lowercased())
            }
            .prefix(limit)
            .enumerated()
            .map { index, item in
                QueryLogEntry(
                    domain: item.0,
                    client: index % 2 == 0 ? "Marwan's iPhone" : "Living Room TV",
                    time: "2026-07-28T18:\(String(format: "%02d", 59 - index)):00Z",
                    blocked: item.1,
                    reason: item.1 ? "FilteredBlackList" : "NotFilteredNotFound"
                )
            }
    }

    func blocklists() async throws -> [Blocklist] { userBlocklists }

    func addBlocklist(name: String, url: String) async throws -> BrickActionResult {
        userBlocklists.append(
            Blocklist(id: nextBlocklistID, name: name, url: url, enabled: true, rulesCount: 0)
        )
        nextBlocklistID += 1
        return BrickActionResult(ok: true, message: "Blocklist added")
    }

    func removeBlocklist(url: String) async throws -> BrickActionResult {
        userBlocklists.removeAll { $0.url == url }
        return BrickActionResult(ok: true, message: "Blocklist removed")
    }

    func setDomainRule(domain: String, action: DomainRuleAction) async throws -> BrickActionResult {
        BrickActionResult(ok: true, message: action == .deny ? "\(domain) blocked" : "\(domain) allowed")
    }

    func dnsStats() async throws -> DNSStats {
        DNSStats(totalQueries: 38_922, cacheHits: 31_150, cacheHitRate: 0.8, avgResponseMs: 12.4)
    }

    func flushDNSCache() async throws -> BrickActionResult {
        BrickActionResult(ok: true, message: "DNS cache cleared")
    }

    func restartPrivateDNS() async throws -> BrickActionResult {
        BrickActionResult(ok: true, message: "Private DNS restarted")
    }

    func remoteAccessStatus() async throws -> RemoteAccessStatus {
        RemoteAccessStatus(
            state: remoteAccessOn ? "Running" : "Stopped",
            hostname: "privacybrick",
            tailscaleIPs: ["100.101.102.103"],
            peers: [
                RemoteAccessPeer(hostname: "marwans-iphone", os: "iOS", online: true, ips: ["100.99.98.97"]),
                RemoteAccessPeer(hostname: "macbook-pro", os: "macOS", online: false, ips: ["100.96.95.94"]),
            ]
        )
    }

    func setRemoteAccess(enabled: Bool) async throws -> BrickActionResult {
        remoteAccessOn = enabled
        return BrickActionResult(ok: true, message: enabled ? "Remote access enabled" : "Remote access paused")
    }

    func setCloudFiltering(enabled: Bool) async throws -> BrickActionResult {
        cloudFilteringOn = enabled
        return BrickActionResult(ok: true, message: enabled ? "Cloud filtering on" : "Cloud filtering off")
    }

    func networkDevices() async throws -> [NetworkDevice] {
        [
            NetworkDevice(ip: "192.168.1.10", name: "Marwan's iPhone", bytesSent: 182_000_000, bytesReceived: 1_400_000_000, activeFlows: 24),
            NetworkDevice(ip: "192.168.1.11", name: "Living Room TV", bytesSent: 48_000_000, bytesReceived: 6_800_000_000, activeFlows: 9),
            NetworkDevice(ip: "192.168.1.12", name: "Thermostat", bytesSent: 2_100_000, bytesReceived: 900_000, activeFlows: 2),
        ]
    }

    func deviceHealth() async throws -> DeviceHealth {
        DeviceHealth(hostname: "privacybrick", uptime: "3 weeks, 2 days",
                     cpuTempCelsius: 47.2, memoryTotalMb: 3796, memoryUsedMb: 812,
                     diskUsedPercent: "23%", dietpiVersion: "9.6.1")
    }

    func rebootDevice() async throws -> BrickActionResult {
        BrickActionResult(ok: true, message: "Rebooting…")
    }
}

/// Instantly "finds" the demo brick — previews and UI tests never wait on mDNS.
@Observable
@MainActor
final class MockDeviceLocator: DeviceLocator {
    private(set) var found: [DiscoveredBrick] = []

    func start() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            found = [DiscoveredBrick(id: "demo", name: "PrivacyBrick (Demo)",
                                     host: "127.0.0.1", port: 8787)]
        }
    }

    func stop() {}
}
