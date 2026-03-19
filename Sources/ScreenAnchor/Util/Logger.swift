import os

enum Log {
    private static let subsystem = "com.screenanchor.app"

    static let general = os.Logger(subsystem: subsystem, category: "general")
    static let screen = os.Logger(subsystem: subsystem, category: "screen")
    static let window = os.Logger(subsystem: subsystem, category: "window")
    static let config = os.Logger(subsystem: subsystem, category: "config")
    static let rule = os.Logger(subsystem: subsystem, category: "rule")
    static let snapshot = os.Logger(subsystem: subsystem, category: "snapshot")
}
