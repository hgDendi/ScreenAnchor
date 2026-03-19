import Cocoa
import ApplicationServices

final class WindowManager {

    struct WindowInfo {
        let pid: pid_t
        let bundleId: String?
        let appName: String
        let title: String?
        let frame: CGRect
        let axWindow: AXUIElement
    }

    func getAllWindows() -> [WindowInfo] {
        guard AccessibilityHelper.isTrusted else {
            Log.window.warning("Accessibility not trusted, cannot enumerate windows")
            return []
        }

        var result: [WindowInfo] = []
        let workspace = NSWorkspace.shared

        for app in workspace.runningApplications where app.activationPolicy == .regular {
            let pid = app.processIdentifier
            let bundleId = app.bundleIdentifier
            let appName = app.localizedName ?? "Unknown"

            let appElement = AXUIElementCreateApplication(pid)
            var windowsRef: CFTypeRef?
            let err = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
            guard err == .success, let windows = windowsRef as? [AXUIElement] else { continue }

            for window in windows {
                guard let frame = getWindowFrame(window) else { continue }
                // Skip tiny windows (likely utility windows)
                if frame.width < 50 || frame.height < 50 { continue }

                let title = getWindowTitle(window)
                result.append(WindowInfo(
                    pid: pid,
                    bundleId: bundleId,
                    appName: appName,
                    title: title,
                    frame: frame,
                    axWindow: window
                ))
            }
        }

        return result
    }

    func getWindows(bundleId: String) -> [WindowInfo] {
        guard AccessibilityHelper.isTrusted else { return [] }

        let workspace = NSWorkspace.shared
        guard let app = workspace.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) else {
            return []
        }

        let pid = app.processIdentifier
        let appName = app.localizedName ?? "Unknown"
        let appElement = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        guard err == .success, let windows = windowsRef as? [AXUIElement] else { return [] }

        return windows.compactMap { window in
            guard let frame = getWindowFrame(window) else { return nil }
            if frame.width < 50 || frame.height < 50 { return nil }
            let title = getWindowTitle(window)
            return WindowInfo(pid: pid, bundleId: bundleId, appName: appName, title: title, frame: frame, axWindow: window)
        }
    }

    func moveWindow(_ window: AXUIElement, to point: CGPoint) {
        var position = point
        let positionValue = AXValueCreate(.cgPoint, &position)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    }

    func resizeWindow(_ window: AXUIElement, to size: CGSize) {
        var sz = size
        let sizeValue = AXValueCreate(.cgSize, &sz)!
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    }

    func moveWindow(_ window: AXUIElement, toFrame frame: CGRect) {
        moveWindow(window, to: frame.origin)
        resizeWindow(window, to: frame.size)
    }

    func moveWindowToScreen(_ window: AXUIElement, currentFrame: CGRect, targetScreen: ScreenInfo) {
        // Calculate relative position within the current screen, then map to target screen
        let targetFrame = targetScreen.frame

        // Find which screen the window is currently on
        let currentScreens = NSScreen.screens
        let currentScreen = currentScreens.first { screen in
            let screenFrame = screen.frame
            return screenFrame.contains(CGPoint(x: currentFrame.midX, y: currentFrame.midY))
        } ?? currentScreens.first!

        let sourceFrame = currentScreen.frame

        // Calculate relative position (0..1)
        let relX = (currentFrame.origin.x - sourceFrame.origin.x) / sourceFrame.width
        let relY = (currentFrame.origin.y - sourceFrame.origin.y) / sourceFrame.height
        let relW = currentFrame.width / sourceFrame.width
        let relH = currentFrame.height / sourceFrame.height

        // Map to target screen
        let newX = targetFrame.origin.x + relX * targetFrame.width
        let newY = targetFrame.origin.y + relY * targetFrame.height
        let newW = min(relW * targetFrame.width, targetFrame.width)
        let newH = min(relH * targetFrame.height, targetFrame.height)

        let newFrame = CGRect(x: newX, y: newY, width: newW, height: newH)
        moveWindow(window, toFrame: newFrame)
        Log.window.info("Moved window to screen \(targetScreen.name) at \(newFrame.debugDescription)")
    }

    // MARK: - Private

    private func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success
        else { return nil }

        var position = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)

        return CGRect(origin: position, size: size)
    }

    private func getWindowTitle(_ window: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef) == .success else {
            return nil
        }
        return titleRef as? String
    }
}
