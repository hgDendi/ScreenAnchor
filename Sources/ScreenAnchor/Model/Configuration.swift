import Foundation

struct ScreenAlias: Codable {
    let alias: String
    let nameContains: String
}

struct ProfileDef: Codable {
    let screenCount: Int
}

struct Configuration: Codable {
    let version: Int
    let debounceMs: Int?
    let screens: [ScreenAlias]
    let rules: [Rule]
    let profiles: [String: ProfileDef]?

    var debounceMilliseconds: Int {
        debounceMs ?? 500
    }

    func screenAlias(for screenName: String) -> String? {
        screens.first { screenName.localizedCaseInsensitiveContains($0.nameContains) }?.alias
    }

    func profileName(for screenCount: Int) -> String? {
        profiles?.first { $0.value.screenCount == screenCount }?.key
    }

    static let `default` = Configuration(
        version: 1,
        debounceMs: 500,
        screens: [
            ScreenAlias(alias: "dell-portrait", nameContains: "U2723QE"),
            ScreenAlias(alias: "dell-main", nameContains: "UP2720Q"),
            ScreenAlias(alias: "macbook", nameContains: "Built-in"),
        ],
        rules: [
            Rule(app: AppMatcher(bundleId: "com.mitchellh.ghostty", nameContains: nil),
                 targetScreen: "dell-portrait", profileOverrides: nil),
            Rule(app: AppMatcher(bundleId: "com.googlecode.iterm2", nameContains: nil),
                 targetScreen: "dell-portrait", profileOverrides: nil),
            Rule(app: AppMatcher(bundleId: "com.electron.lark", nameContains: nil),
                 targetScreen: "macbook", profileOverrides: nil),
            Rule(app: AppMatcher(bundleId: "com.google.Chrome", nameContains: nil),
                 targetScreen: "dell-main",
                 profileOverrides: ["2-screen": "macbook"]),
        ],
        profiles: [
            "3-screen": ProfileDef(screenCount: 3),
            "2-screen": ProfileDef(screenCount: 2),
        ]
    )
}
