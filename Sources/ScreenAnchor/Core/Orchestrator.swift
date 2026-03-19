import Cocoa
import Combine

final class Orchestrator: ObservableObject {
    @Published var autoApplyOnScreenChange = true
    @Published var autoApplyOnAppLaunch = true
    @Published private(set) var lastAction: String = ""

    let screenDetector: ScreenDetector
    let configManager: ConfigManager
    let windowManager: WindowManager
    let snapshotStore: LayoutSnapshotStore
    let ruleEngine: RuleEngine

    private var cancellables = Set<AnyCancellable>()
    private var previousProfileKey: String = ""

    init() {
        screenDetector = ScreenDetector()
        configManager = ConfigManager()
        windowManager = WindowManager()
        snapshotStore = LayoutSnapshotStore()
        ruleEngine = RuleEngine()

        previousProfileKey = screenDetector.profileKey

        setupScreenChangeHandler()
        setupAppLaunchHandler()
    }

    func applyAllRules() {
        guard AccessibilityHelper.isTrusted else {
            lastAction = "Accessibility permission required"
            AccessibilityHelper.requestAccess()
            return
        }

        let config = configManager.configuration
        let matches = ruleEngine.matchRules(configuration: config, screenCount: screenDetector.screenCount)

        var applied = 0
        for match in matches {
            guard let targetScreen = screenDetector.screenInfo(forAlias: match.targetScreenAlias, configuration: config)
            else {
                Log.rule.warning("Target screen '\(match.targetScreenAlias)' not found for \(match.bundleId)")
                continue
            }

            let windows = windowManager.getWindows(bundleId: match.bundleId)
            for win in windows {
                // Check if window is already on the target screen
                if targetScreen.frame.contains(CGPoint(x: win.frame.midX, y: win.frame.midY)) {
                    continue
                }
                windowManager.moveWindowToScreen(win.axWindow, currentFrame: win.frame, targetScreen: targetScreen)
                applied += 1
            }
        }

        lastAction = "Applied \(applied) window moves"
        Log.rule.info("\(self.lastAction)")
    }

    func saveCurrentLayout() {
        let profileKey = screenDetector.profileKey
        let snapshot = snapshotStore.captureSnapshot(
            profileKey: profileKey,
            windowManager: windowManager,
            screens: screenDetector.screens
        )
        snapshotStore.save(snapshot: snapshot)
        lastAction = "Saved layout (\(snapshot.windows.count) windows)"
        Log.snapshot.info("\(self.lastAction)")
    }

    // MARK: - Private

    private func setupScreenChangeHandler() {
        screenDetector.onScreensChanged
            .sink { [weak self] newProfileKey in
                guard let self, self.autoApplyOnScreenChange else { return }
                self.handleScreenChange(newProfileKey: newProfileKey)
            }
            .store(in: &cancellables)
    }

    private func handleScreenChange(newProfileKey: String) {
        guard AccessibilityHelper.isTrusted else { return }

        let oldProfileKey = previousProfileKey
        Log.general.info("Screen change: '\(oldProfileKey)' -> '\(newProfileKey)'")

        // Step 1: Save current layout to old profile (before screens actually change)
        // Note: By this point the screens have already changed, so we capture what we can
        screenDetector.refreshScreens()

        // Step 2: Apply rules first (higher priority)
        let config = configManager.configuration
        let matches = ruleEngine.matchRules(configuration: config, screenCount: screenDetector.screenCount)
        let ruleBundleIds = Set(matches.map { $0.bundleId })

        for match in matches {
            guard let targetScreen = screenDetector.screenInfo(forAlias: match.targetScreenAlias, configuration: config)
            else { continue }

            let windows = windowManager.getWindows(bundleId: match.bundleId)
            for win in windows {
                if targetScreen.frame.contains(CGPoint(x: win.frame.midX, y: win.frame.midY)) {
                    continue
                }
                windowManager.moveWindowToScreen(win.axWindow, currentFrame: win.frame, targetScreen: targetScreen)
            }
        }

        // Step 3: Restore snapshot for non-rule apps
        if let snapshot = snapshotStore.load(profileKey: newProfileKey) {
            snapshotStore.restoreSnapshot(snapshot, windowManager: windowManager, excludeBundleIds: ruleBundleIds)
            Log.snapshot.info("Restored snapshot for profile '\(newProfileKey)'")
        }

        // Step 4: Save new layout state
        let newSnapshot = snapshotStore.captureSnapshot(
            profileKey: newProfileKey,
            windowManager: windowManager,
            screens: screenDetector.screens
        )
        snapshotStore.save(snapshot: newSnapshot)

        previousProfileKey = newProfileKey
        lastAction = "Screen changed: applied rules + restored layout"
    }

    private func setupAppLaunchHandler() {
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] app in
                guard let self, self.autoApplyOnAppLaunch else { return }
                self.handleAppLaunch(app)
            }
            .store(in: &cancellables)
    }

    private func handleAppLaunch(_ app: NSRunningApplication) {
        guard AccessibilityHelper.isTrusted else { return }

        let bundleId = app.bundleIdentifier
        let appName = app.localizedName

        let config = configManager.configuration
        guard let match = ruleEngine.matchRule(
            for: bundleId, appName: appName,
            configuration: config,
            screenCount: screenDetector.screenCount
        ) else { return }

        guard let targetScreen = screenDetector.screenInfo(forAlias: match.targetScreenAlias, configuration: config)
        else { return }

        // Small extra delay to ensure window is created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            let windows = self.windowManager.getWindows(bundleId: match.bundleId)
            for win in windows {
                if targetScreen.frame.contains(CGPoint(x: win.frame.midX, y: win.frame.midY)) {
                    continue
                }
                self.windowManager.moveWindowToScreen(win.axWindow, currentFrame: win.frame, targetScreen: targetScreen)
            }
            Log.rule.info("Applied launch rule: \(appName ?? "unknown") -> \(match.targetScreenAlias)")
            self.lastAction = "Moved \(appName ?? "app") to \(match.targetScreenAlias)"
        }
    }
}
