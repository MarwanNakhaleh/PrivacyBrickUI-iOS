import Foundation
import Network
import Observation

/// Browses for `_privacybrick._tcp` over Bonjour and resolves each service to
/// host:port. Used only on first run (or re-pairing) — after pairing, the
/// EndpointResolver's stored candidates take over.
@Observable
@MainActor
final class BonjourDiscovery: DeviceLocator {
    private(set) var found: [DiscoveredBrick] = []

    @ObservationIgnored private var browser: NWBrowser?
    @ObservationIgnored private var resolvers: [NWConnection] = []

    func start() {
        stop()
        found = []

        let params = NWParameters()
        params.includePeerToPeer = true
        let browser = NWBrowser(
            for: .bonjour(type: "_privacybrick._tcp", domain: nil),
            using: params
        )
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in self?.resolve(results) }
        }
        browser.start(queue: .main)
        self.browser = browser
    }

    func stop() {
        browser?.cancel()
        browser = nil
        resolvers.forEach { $0.cancel() }
        resolvers = []
    }

    private func resolve(_ results: Set<NWBrowser.Result>) {
        for result in results {
            guard case let .service(name, _, _, _) = result.endpoint else { continue }
            // A throwaway TCP connection resolves the service to a concrete
            // host:port; it's cancelled the moment we have the address.
            let connection = NWConnection(to: result.endpoint, using: .tcp)
            resolvers.append(connection)
            connection.stateUpdateHandler = { [weak self, weak connection] state in
                guard case .ready = state,
                      let endpoint = connection?.currentPath?.remoteEndpoint,
                      case let .hostPort(host, port) = endpoint
                else { return }
                let brick = DiscoveredBrick(
                    id: name,
                    name: name,
                    host: Self.hostString(host),
                    port: Int(port.rawValue)
                )
                Task { @MainActor in
                    guard let self else { return }
                    self.found.removeAll { $0.id == brick.id }
                    self.found.append(brick)
                    connection?.cancel()
                }
            }
            connection.start(queue: .main)
        }
    }

    private static func hostString(_ host: NWEndpoint.Host) -> String {
        switch host {
        case let .ipv4(address): return "\(address)"
        case let .ipv6(address): return "[\(address)]"
        case let .name(name, _): return name
        @unknown default: return "\(host)"
        }
    }
}
