import Foundation

// Domain models for the PrivacyBrick appliance. Pure value types — no SwiftUI,
// no URLSession. Codable conformance uses explicit keys so the wire contract
// with PrivacyBrickAPI is visible and exact.

/// One protection layer on the brick, in layperson vocabulary
/// ("Ad Blocking", "Private DNS"), never the daemon name.
struct ServiceStatus: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let running: Bool
    let installed: Bool
    let detail: String
}

/// Everything the home screen needs, from one call.
struct BrickOverview: Codable, Equatable {
    let deviceName: String
    let protected: Bool
    let services: [ServiceStatus]

    enum CodingKeys: String, CodingKey {
        case protected, services
        case deviceName = "device_name"
    }
}

/// Result of exchanging a pairing code for a long-lived token.
struct PairingGrant: Codable, Equatable {
    let token: String
    let deviceName: String

    enum CodingKeys: String, CodingKey {
        case token
        case deviceName = "device_name"
    }
}

/// Where the brick can be reached. The Tailscale addresses are what make
/// "never think about local vs. remote" possible.
struct BrickIdentity: Codable, Equatable {
    let deviceName: String
    let version: String
    let port: Int
    let lanIP: String
    let tailscaleIPs: [String]
    let magicDNSName: String

    enum CodingKeys: String, CodingKey {
        case version, port
        case deviceName = "device_name"
        case lanIP = "lan_ip"
        case tailscaleIPs = "tailscale_ips"
        case magicDNSName = "magicdns_name"
    }
}

struct BrickActionResult: Codable, Equatable {
    let ok: Bool
    let message: String
}

// MARK: - Ad Blocking

struct AdBlockStats: Codable, Equatable {
    let totalQueries: Int
    let blocked: Int
    let blockedPercent: Double

    enum CodingKeys: String, CodingKey {
        case blocked
        case totalQueries = "total_queries"
        case blockedPercent = "blocked_percent"
    }
}

struct QueryLogEntry: Codable, Identifiable, Hashable {
    let domain: String
    let client: String
    let time: String
    let blocked: Bool
    let reason: String

    var id: String { "\(time)|\(domain)|\(client)" }
}

struct QueryLogPage: Codable, Equatable {
    let entries: [QueryLogEntry]
}

struct Blocklist: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let url: String
    let enabled: Bool
    let rulesCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, url, enabled
        case rulesCount = "rules_count"
    }
}

struct BlocklistPage: Codable, Equatable {
    let blocklists: [Blocklist]
}

enum DomainRuleAction: String, Codable {
    case allow
    case deny
}

// MARK: - Private DNS

struct DNSStats: Codable, Equatable {
    let totalQueries: Int
    let cacheHits: Int
    let cacheHitRate: Double
    let avgResponseMs: Double

    enum CodingKeys: String, CodingKey {
        case totalQueries = "total_queries"
        case cacheHits = "cache_hits"
        case cacheHitRate = "cache_hit_rate"
        case avgResponseMs = "avg_response_ms"
    }
}

// MARK: - Remote Access

struct RemoteAccessPeer: Codable, Identifiable, Hashable {
    let hostname: String
    let os: String
    let online: Bool
    let ips: [String]

    var id: String { hostname + ips.joined(separator: ",") }
}

struct RemoteAccessStatus: Codable, Equatable {
    let state: String
    let hostname: String
    let tailscaleIPs: [String]
    let peers: [RemoteAccessPeer]

    enum CodingKeys: String, CodingKey {
        case state, hostname, peers
        case tailscaleIPs = "tailscale_ips"
    }

    var isRunning: Bool { state == "Running" }
}

// MARK: - Network Monitor

struct NetworkDevice: Codable, Identifiable, Hashable {
    let ip: String
    let name: String
    let bytesSent: Int
    let bytesReceived: Int
    let activeFlows: Int

    var id: String { ip }

    enum CodingKeys: String, CodingKey {
        case ip, name
        case bytesSent = "bytes_sent"
        case bytesReceived = "bytes_received"
        case activeFlows = "active_flows"
    }
}

struct NetworkDevicePage: Codable, Equatable {
    let hosts: [NetworkDevice]
}

// MARK: - Device

struct DeviceHealth: Codable, Equatable {
    let hostname: String
    let uptime: String
    let cpuTempCelsius: Double?
    let memoryTotalMb: Int?
    let memoryUsedMb: Int?
    let diskUsedPercent: String?
    let dietpiVersion: String?

    enum CodingKeys: String, CodingKey {
        case hostname, uptime
        case cpuTempCelsius = "cpu_temp_celsius"
        case memoryTotalMb = "memory_total_mb"
        case memoryUsedMb = "memory_used_mb"
        case diskUsedPercent = "disk_used_percent"
        case dietpiVersion = "dietpi_version"
    }
}

/// A brick found on the local network during onboarding.
struct DiscoveredBrick: Identifiable, Hashable {
    let id: String
    let name: String
    let host: String
    let port: Int
}
