import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

enum ScreenPosition: String, Codable {
    case leftmost
    case center
    case rightmost
    case single
}

struct ScreenInfo: Identifiable {
    let displayID: CGDirectDisplayID
    let name: String
    let frame: CGRect
    let isBuiltIn: Bool
    let position: ScreenPosition
    let vendorID: UInt32
    let modelID: UInt32
    let serialNumber: UInt32
    /// Stable identifier for this physical display.
    /// Preferred source: CGDisplayCreateUUIDFromDisplayID (survives reboots / cable swaps).
    /// Falls back to "vendor-model-serial", then to "display-<id>" when even that is unavailable.
    /// Note: many displays report serialNumber == 0, which is why a UUID-based ID is preferred.
    let persistentID: String

    var id: CGDirectDisplayID { displayID }

    /// Stable hardware-based unique key for this physical display.
    /// Backed by `persistentID` so two displays of the same model are not collapsed.
    var uniqueKey: String { persistentID }

    var shortName: String {
        if isBuiltIn { return "Built-in" }
        let parts = name.split(separator: " ")
        if parts.count > 1 {
            return String(parts.last!)
        }
        return name
    }

    var isPortrait: Bool {
        frame.height > frame.width
    }

    var orientationLabel: String {
        isPortrait ? "portrait" : "landscape"
    }
}

extension ScreenInfo {
    /// Resolve a stable ID for `displayID`. Tries CGDisplay UUID first, then hardware tuple, then displayID.
    static func resolvePersistentID(displayID: CGDirectDisplayID,
                                    vendorID: UInt32,
                                    modelID: UInt32,
                                    serialNumber: UInt32) -> String {
        if let uuidRef = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() {
            let cfString = CFUUIDCreateString(nil, uuidRef)
            if let cfString {
                return cfString as String
            }
        }
        if vendorID != 0 || modelID != 0 || serialNumber != 0 {
            return "\(vendorID)-\(modelID)-\(serialNumber)"
        }
        return "display-\(displayID)"
    }

    /// Convenience initializer that derives `persistentID` automatically.
    init(displayID: CGDirectDisplayID,
         name: String,
         frame: CGRect,
         isBuiltIn: Bool,
         position: ScreenPosition,
         vendorID: UInt32,
         modelID: UInt32,
         serialNumber: UInt32) {
        self.init(
            displayID: displayID,
            name: name,
            frame: frame,
            isBuiltIn: isBuiltIn,
            position: position,
            vendorID: vendorID,
            modelID: modelID,
            serialNumber: serialNumber,
            persistentID: ScreenInfo.resolvePersistentID(
                displayID: displayID,
                vendorID: vendorID,
                modelID: modelID,
                serialNumber: serialNumber
            )
        )
    }
}
