import Cocoa
import Combine
import CoreGraphics

final class ScreenDetector: ObservableObject {
    @Published private(set) var screens: [ScreenInfo] = []
    @Published private(set) var profileKey: String = ""

    private let screenChangeSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var callbackRegistered = false

    var screenCount: Int { screens.count }

    var onScreensChanged: AnyPublisher<String, Never> {
        screenChangeSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .map { [weak self] in self?.profileKey ?? "" }
            .eraseToAnyPublisher()
    }

    init() {
        refreshScreens()
        registerCallback()
    }

    deinit {
        if callbackRegistered {
            CGDisplayRemoveReconfigurationCallback(displayReconfigCallback, Unmanaged.passUnretained(self).toOpaque())
        }
    }

    func refreshScreens() {
        let nsScreens = NSScreen.screens
        var infos: [ScreenInfo] = []

        for screen in nsScreens {
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            let name = screen.localizedName
            let frame = screen.frame
            let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0

            infos.append(ScreenInfo(
                displayID: displayID,
                name: name,
                frame: frame,
                isBuiltIn: isBuiltIn,
                position: .single // will be computed below
            ))
        }

        // Sort by x position and assign positions
        infos.sort { $0.frame.origin.x < $1.frame.origin.x }
        screens = assignPositions(infos)
        profileKey = generateProfileKey(from: screens)
        Log.screen.info("Detected \(self.screens.count) screens, profile: \(self.profileKey)")
    }

    func screenInfo(forAlias alias: String, configuration: Configuration) -> ScreenInfo? {
        guard let screenAlias = configuration.screens.first(where: { $0.alias == alias }) else {
            return nil
        }
        return screens.first { $0.name.localizedCaseInsensitiveContains(screenAlias.nameContains) }
    }

    private func assignPositions(_ infos: [ScreenInfo]) -> [ScreenInfo] {
        guard infos.count > 1 else {
            return infos.map { ScreenInfo(displayID: $0.displayID, name: $0.name, frame: $0.frame, isBuiltIn: $0.isBuiltIn, position: .single) }
        }

        return infos.enumerated().map { index, info in
            let position: ScreenPosition
            if index == 0 {
                position = .leftmost
            } else if index == infos.count - 1 {
                position = .rightmost
            } else {
                position = .center
            }
            return ScreenInfo(displayID: info.displayID, name: info.name, frame: info.frame, isBuiltIn: info.isBuiltIn, position: position)
        }
    }

    private func generateProfileKey(from screens: [ScreenInfo]) -> String {
        screens.map { $0.shortName }.sorted().joined(separator: "|")
    }

    private func registerCallback() {
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(displayReconfigCallback, pointer)
        callbackRegistered = true
    }

    fileprivate func handleDisplayChange(flags: CGDisplayChangeSummaryFlags) {
        // Only respond to add/remove/moved events, not begin/complete config
        if flags.contains(.addFlag) || flags.contains(.removeFlag) ||
           flags.contains(.movedFlag) || flags.contains(.setMainFlag) {
            screenChangeSubject.send()
        }
    }
}

private func displayReconfigCallback(displayID: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags, userInfo: UnsafeMutableRawPointer?) {
    guard let userInfo else { return }
    let detector = Unmanaged<ScreenDetector>.fromOpaque(userInfo).takeUnretainedValue()

    // CGDisplayReconfigurationCallback is called on an arbitrary thread
    DispatchQueue.main.async {
        detector.handleDisplayChange(flags: flags)
    }
}
