import Foundation
import CoreGraphics

struct WindowSnapshot: Codable, Equatable {
    let bundleId: String
    let appName: String
    let windowTitle: String?
    let frame: CodableRect
    let screenName: String

    struct CodableRect: Codable, Equatable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double

        init(_ rect: CGRect) {
            self.x = rect.origin.x
            self.y = rect.origin.y
            self.width = rect.size.width
            self.height = rect.size.height
        }

        var cgRect: CGRect {
            CGRect(x: x, y: y, width: width, height: height)
        }
    }
}
