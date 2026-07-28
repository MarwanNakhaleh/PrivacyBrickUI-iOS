import SwiftUI

/// The physical brick: health, connection route, reboot, unpair.
struct DeviceView: View {
    @Environment(AppModel.self) private var appModel
    @State private var health: DeviceHealth?
    @State private var showRebootConfirm = false
    @State private var showForgetConfirm = false
    @State private var rebooting = false

    var body: some View {
        List {
            if let health {
                Section("Health") {
                    row("Name", health.hostname)
                    row("Up for", health.uptime)
                    if let temp = health.cpuTempCelsius {
                        row("Temperature", temp.formatted(.number.precision(.fractionLength(1))) + " °C")
                    }
                    if let used = health.memoryUsedMb, let total = health.memoryTotalMb {
                        row("Memory", "\(used) / \(total) MB")
                    }
                    if let disk = health.diskUsedPercent {
                        row("Storage used", disk)
                    }
                    if let version = health.dietpiVersion {
                        row("System version", "DietPi \(version)")
                    }
                }
            }

            if let route = appModel.connectionRoute {
                Section("Connection") {
                    Label(route.capitalized, systemImage: "point.3.filled.connected.trianglepath.dotted")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    showRebootConfirm = true
                } label: {
                    Label(rebooting ? "Rebooting…" : "Restart device",
                          systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(rebooting)
                .accessibilityIdentifier("device.rebootButton")
            } footer: {
                Text("Restarting takes about a minute. Internet keeps working through your router while the PrivacyBrick is down — only filtering pauses.")
            }

            Section {
                Button(role: .destructive) {
                    showForgetConfirm = true
                } label: {
                    Label("Forget this device", systemImage: "xmark.circle")
                }
            } footer: {
                Text("Removes this phone's pairing. The PrivacyBrick keeps protecting your network.")
            }
        }
        .navigationTitle("Device")
        .confirmationDialog("Restart your PrivacyBrick?",
                            isPresented: $showRebootConfirm, titleVisibility: .visible) {
            Button("Restart", role: .destructive) { reboot() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Filtering pauses for about a minute while it restarts.")
        }
        .confirmationDialog("Forget this device?",
                            isPresented: $showForgetConfirm, titleVisibility: .visible) {
            Button("Forget", role: .destructive) { appModel.forgetDevice() }
            Button("Cancel", role: .cancel) {}
        }
        .task { health = try? await appModel.api.deviceHealth() }
        .refreshable { health = try? await appModel.api.deviceHealth() }
    }

    private func reboot() {
        rebooting = true
        Task {
            _ = try? await appModel.api.rebootDevice()
            // Give the brick time to go down and come back before refreshing.
            try? await Task.sleep(for: .seconds(5))
            rebooting = false
            await appModel.refresh()
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
