import Foundation
import Cocoa
import Combine

final class ConfigManager: ObservableObject {
    @Published private(set) var configuration: Configuration

    private let configDir: URL
    private let configFileURL: URL
    private var fileMonitor: DispatchSourceFileSystemObject?

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configDir = home.appendingPathComponent(".config/screenanchor")
        configFileURL = configDir.appendingPathComponent("config.json")

        // Start with default config
        configuration = Configuration.default

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

        // Load or create config file
        if FileManager.default.fileExists(atPath: configFileURL.path) {
            loadConfig()
        } else {
            saveDefaultConfig()
        }

        watchConfigFile()
    }

    deinit {
        fileMonitor?.cancel()
    }

    func reload() {
        loadConfig()
    }

    func openConfigInEditor() {
        let url = configFileURL
        NSWorkspace.shared.open(url)
    }

    var configFilePath: String {
        configFileURL.path
    }

    // MARK: - Private

    private func loadConfig() {
        do {
            let data = try Data(contentsOf: configFileURL)
            let decoder = JSONDecoder()
            configuration = try decoder.decode(Configuration.self, from: data)
            Log.config.info("Configuration loaded successfully with \(self.configuration.rules.count) rules")
        } catch {
            Log.config.error("Failed to load config: \(error.localizedDescription). Using defaults.")
            configuration = Configuration.default
        }
    }

    private func saveDefaultConfig() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(Configuration.default)
            try data.write(to: configFileURL)
            Log.config.info("Default configuration saved to \(self.configFileURL.path)")
        } catch {
            Log.config.error("Failed to save default config: \(error.localizedDescription)")
        }
    }

    private func watchConfigFile() {
        let fd = open(configFileURL.path, O_EVTONLY)
        guard fd >= 0 else {
            Log.config.warning("Cannot watch config file")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            Log.config.info("Config file changed, reloading...")
            // Small delay to ensure the file write is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.loadConfig()
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileMonitor = source
    }
}
