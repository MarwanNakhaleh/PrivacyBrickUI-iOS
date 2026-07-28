import Foundation

/// Errors in the app's own vocabulary. Infrastructure translates transport
/// errors (URLError, HTTP statuses) into these at the boundary.
enum BrickError: LocalizedError, Equatable {
    case notPaired
    case pairingRejected(String)
    case unauthorized
    case unreachable
    case deviceError(String)

    var errorDescription: String? {
        switch self {
        case .notPaired:
            return "Not connected to a PrivacyBrick yet."
        case let .pairingRejected(message):
            return message
        case .unauthorized:
            return "This phone is no longer paired. Pair again with a new code."
        case .unreachable:
            return "Can't reach your PrivacyBrick right now."
        case let .deviceError(message):
            return message
        }
    }
}

/// The port to the appliance. Features depend on this protocol only;
/// the composition root decides whether it's HTTP or a mock.
protocol BrickAPI {
    // Session
    func pair(code: String) async throws -> PairingGrant
    func identity() async throws -> BrickIdentity
    func overview() async throws -> BrickOverview

    // Ad Blocking
    func adBlockStats() async throws -> AdBlockStats
    func setAdBlocking(enabled: Bool) async throws -> BrickActionResult
    func queryLog(limit: Int, search: String?) async throws -> [QueryLogEntry]
    func blocklists() async throws -> [Blocklist]
    func addBlocklist(name: String, url: String) async throws -> BrickActionResult
    func removeBlocklist(url: String) async throws -> BrickActionResult
    func setDomainRule(domain: String, action: DomainRuleAction) async throws -> BrickActionResult

    // Private DNS
    func dnsStats() async throws -> DNSStats
    func flushDNSCache() async throws -> BrickActionResult
    func restartPrivateDNS() async throws -> BrickActionResult

    // Remote Access
    func remoteAccessStatus() async throws -> RemoteAccessStatus
    func setRemoteAccess(enabled: Bool) async throws -> BrickActionResult

    // Cloud Filtering
    func setCloudFiltering(enabled: Bool) async throws -> BrickActionResult

    // Network Monitor
    func networkDevices() async throws -> [NetworkDevice]

    // Device
    func deviceHealth() async throws -> DeviceHealth
    func rebootDevice() async throws -> BrickActionResult
}
