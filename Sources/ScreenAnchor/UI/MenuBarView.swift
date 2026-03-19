import SwiftUI

struct MenuBarView: View {
    @ObservedObject var orchestrator: Orchestrator
    @State private var launchAtLogin = LoginItemManager.isEnabled

    private var screenDetector: ScreenDetector { orchestrator.screenDetector }
    private var isTrusted: Bool { AccessibilityHelper.isTrusted }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status
            if !isTrusted {
                Label("Accessibility Permission Required", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)

                Button("Grant Permission...") {
                    AccessibilityHelper.requestAccess()
                }
                .padding(.horizontal, 8)

                Divider().padding(.vertical, 4)
            }

            Label("\(screenDetector.screens.count) screen\(screenDetector.screens.count == 1 ? "" : "s") detected",
                  systemImage: "display")
                .padding(.horizontal, 8)
                .padding(.vertical, 2)

            Divider().padding(.vertical, 4)

            // Screen list
            Text("Screens:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            ForEach(screenDetector.screens) { screen in
                HStack(spacing: 4) {
                    Image(systemName: screen.isBuiltIn ? "laptopcomputer" : "display")
                        .frame(width: 16)
                    Text(screen.name)
                    Text("(\(screen.position.rawValue), \(screen.orientationLabel))")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 1)
            }

            if !orchestrator.lastAction.isEmpty {
                Divider().padding(.vertical, 4)
                Text(orchestrator.lastAction)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }

            Divider().padding(.vertical, 4)

            // Actions
            Button {
                orchestrator.applyAllRules()
            } label: {
                Label("Apply All Rules Now", systemImage: "arrow.right.square")
            }
            .disabled(!isTrusted)

            Button {
                orchestrator.saveCurrentLayout()
            } label: {
                Label("Save Current Layout", systemImage: "square.and.arrow.down")
            }
            .disabled(!isTrusted)

            Divider().padding(.vertical, 4)

            // Toggles
            Toggle(isOn: $orchestrator.autoApplyOnScreenChange) {
                Text("Auto-apply on screen change")
            }
            .toggleStyle(.checkbox)
            .padding(.horizontal, 8)

            Toggle(isOn: $orchestrator.autoApplyOnAppLaunch) {
                Text("Auto-apply on app launch")
            }
            .toggleStyle(.checkbox)
            .padding(.horizontal, 8)

            Divider().padding(.vertical, 4)

            // Config
            Button("Edit Config...") {
                orchestrator.configManager.openConfigInEditor()
            }

            Button("Reload Config") {
                orchestrator.configManager.reload()
            }

            Divider().padding(.vertical, 4)

            // System
            Toggle(isOn: $launchAtLogin) {
                Text("Launch at Login")
            }
            .toggleStyle(.checkbox)
            .padding(.horizontal, 8)
            .onChange(of: launchAtLogin) { newValue in
                LoginItemManager.setEnabled(newValue)
            }

            Button("About ScreenAnchor") {
                showAbout()
            }

            Divider().padding(.vertical, 4)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(.vertical, 4)
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "ScreenAnchor"
        alert.informativeText = """
        Version 1.0.0

        Multi-screen window manager for macOS.
        Automatically saves and restores window layouts when screens change.

        Config: \(orchestrator.configManager.configFilePath)
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
