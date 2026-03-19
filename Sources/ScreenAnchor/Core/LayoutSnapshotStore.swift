import Foundation

final class LayoutSnapshotStore {
    private let snapshotDir: URL
    private var cache: [String: LayoutSnapshot] = [:]

    init() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/screenanchor/snapshots")
        self.snapshotDir = configDir

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        loadAll()
    }

    func save(snapshot: LayoutSnapshot) {
        cache[snapshot.profileKey] = snapshot

        let fileURL = snapshotDir.appendingPathComponent("\(sanitize(snapshot.profileKey)).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL)
            Log.snapshot.info("Saved snapshot for profile '\(snapshot.profileKey)' with \(snapshot.windows.count) windows")
        } catch {
            Log.snapshot.error("Failed to save snapshot: \(error.localizedDescription)")
        }
    }

    func load(profileKey: String) -> LayoutSnapshot? {
        if let cached = cache[profileKey] {
            return cached
        }

        let fileURL = snapshotDir.appendingPathComponent("\(sanitize(profileKey)).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try decoder.decode(LayoutSnapshot.self, from: data)
            cache[profileKey] = snapshot
            return snapshot
        } catch {
            Log.snapshot.error("Failed to load snapshot for '\(profileKey)': \(error.localizedDescription)")
            return nil
        }
    }

    func captureSnapshot(profileKey: String, windowManager: WindowManager, screens: [ScreenInfo]) -> LayoutSnapshot {
        let allWindows = windowManager.getAllWindows()
        let windowSnapshots = allWindows.map { win -> WindowSnapshot in
            let screenName = findScreen(for: win.frame, in: screens)?.name ?? "Unknown"
            return WindowSnapshot(
                bundleId: win.bundleId ?? "",
                appName: win.appName,
                windowTitle: win.title,
                frame: WindowSnapshot.CodableRect(win.frame),
                screenName: screenName
            )
        }

        let snapshot = LayoutSnapshot(
            profileKey: profileKey,
            timestamp: Date(),
            windows: windowSnapshots
        )
        return snapshot
    }

    func restoreSnapshot(_ snapshot: LayoutSnapshot, windowManager: WindowManager, excludeBundleIds: Set<String>) {
        let allWindows = windowManager.getAllWindows()

        for savedWindow in snapshot.windows {
            guard !excludeBundleIds.contains(savedWindow.bundleId) else { continue }

            // Find matching running window
            if let runningWindow = allWindows.first(where: { $0.bundleId == savedWindow.bundleId }) {
                windowManager.moveWindow(runningWindow.axWindow, toFrame: savedWindow.frame.cgRect)
                Log.snapshot.info("Restored \(savedWindow.appName) to saved position")
            }
        }
    }

    // MARK: - Private

    private func loadAll() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: snapshotDir, includingPropertiesForKeys: nil)
        else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let snapshot = try? decoder.decode(LayoutSnapshot.self, from: data) {
                cache[snapshot.profileKey] = snapshot
            }
        }
        Log.snapshot.info("Loaded \(self.cache.count) cached snapshots")
    }

    private func sanitize(_ key: String) -> String {
        key.replacingOccurrences(of: "|", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    private func findScreen(for windowFrame: CGRect, in screens: [ScreenInfo]) -> ScreenInfo? {
        let windowCenter = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        return screens.first { $0.frame.contains(windowCenter) }
    }
}
