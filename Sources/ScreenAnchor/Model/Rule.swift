import Foundation

struct AppMatcher: Codable {
    let bundleId: String?
    let nameContains: String?

    func matches(bundleId bid: String?, appName: String?) -> Bool {
        if let bundleId, let bid, bundleId == bid {
            return true
        }
        if let nameContains, let appName,
           appName.localizedCaseInsensitiveContains(nameContains) {
            return true
        }
        return false
    }
}

struct Rule: Codable {
    let app: AppMatcher
    let targetScreen: String
    let profileOverrides: [String: String]?

    func resolvedTargetScreen(for profileName: String?) -> String {
        if let profileName,
           let overrides = profileOverrides,
           let override = overrides[profileName] {
            return override
        }
        return targetScreen
    }
}
