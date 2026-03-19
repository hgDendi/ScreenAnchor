import ServiceManagement

enum LoginItemManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                Log.general.info("Login item registered")
            } else {
                try SMAppService.mainApp.unregister()
                Log.general.info("Login item unregistered")
            }
        } catch {
            Log.general.error("Failed to update login item: \(error.localizedDescription)")
        }
    }
}
