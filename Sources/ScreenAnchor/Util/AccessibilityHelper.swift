import Cocoa
import ApplicationServices

enum AccessibilityHelper {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func ensureAccess() -> Bool {
        if isTrusted { return true }
        requestAccess()
        return false
    }
}
