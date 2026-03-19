import Foundation
import CoreGraphics

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

    var id: CGDirectDisplayID { displayID }

    var shortName: String {
        if isBuiltIn { return "Built-in" }
        // Extract model name like "U2723QE" from "DELL U2723QE"
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
