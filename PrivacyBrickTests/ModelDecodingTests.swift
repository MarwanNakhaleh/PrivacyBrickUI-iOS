import XCTest
@testable import PrivacyBrick

/// Pins the wire contract with PrivacyBrickAPI: these JSON fixtures are the
/// exact shapes the Pi returns. If decoding breaks here, the app would break
/// against the real device.
final class ModelDecodingTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    func testOverviewDecoding() throws {
        let overview = try decode(BrickOverview.self, """
        {"device_name": "PrivacyBrick", "protected": true,
         "services": [{"id": "adguard", "name": "Ad Blocking", "running": true,
                       "installed": true, "detail": "protecting"}]}
        """)
        XCTAssertEqual(overview.deviceName, "PrivacyBrick")
        XCTAssertTrue(overview.protected)
        XCTAssertEqual(overview.services.first?.name, "Ad Blocking")
    }

    func testIdentityDecoding() throws {
        let identity = try decode(BrickIdentity.self, """
        {"device_name": "PrivacyBrick", "version": "0.1.0", "port": 8787,
         "lan_ip": "192.168.1.42", "tailscale_ips": ["100.101.102.103"],
         "magicdns_name": "privacybrick.tail1234.ts.net"}
        """)
        XCTAssertEqual(identity.tailscaleIPs, ["100.101.102.103"])
        XCTAssertEqual(identity.magicDNSName, "privacybrick.tail1234.ts.net")
        XCTAssertEqual(identity.port, 8787)
    }

    func testQueryLogDecoding() throws {
        let page = try decode(QueryLogPage.self, """
        {"entries": [{"domain": "doubleclick.net", "client": "192.168.1.10",
                      "time": "2026-07-28T18:59:00Z", "blocked": true,
                      "reason": "FilteredBlackList"}]}
        """)
        XCTAssertEqual(page.entries.count, 1)
        XCTAssertTrue(page.entries[0].blocked)
        XCTAssertEqual(page.entries[0].domain, "doubleclick.net")
    }

    func testBlocklistDecoding() throws {
        let page = try decode(BlocklistPage.self, """
        {"blocklists": [{"id": 1, "name": "OISD", "url": "https://abp.oisd.nl/basic/",
                         "enabled": true, "rules_count": 212340}]}
        """)
        XCTAssertEqual(page.blocklists.first?.rulesCount, 212_340)
    }

    func testDeviceHealthDecodingWithNulls() throws {
        // A brick that can't read its temperature must still decode.
        let health = try decode(DeviceHealth.self, """
        {"hostname": "privacybrick", "uptime": "3 weeks", "cpu_temp_celsius": null,
         "memory_total_mb": null, "memory_used_mb": null,
         "disk_used_percent": null, "dietpi_version": null}
        """)
        XCTAssertNil(health.cpuTempCelsius)
        XCTAssertEqual(health.hostname, "privacybrick")
    }

    func testPairingGrantDecoding() throws {
        let grant = try decode(PairingGrant.self, """
        {"token": "abc123", "device_name": "PrivacyBrick"}
        """)
        XCTAssertEqual(grant.token, "abc123")
    }
}
