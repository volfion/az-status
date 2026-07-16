import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    enum Language: String, CaseIterable, Identifiable {
        case cs, en, de, sk, pl
        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .cs: return "Čeština"
            case .en: return "English"
            case .de: return "Deutsch"
            case .sk: return "Slovenčina"
            case .pl: return "Polski"
            }
        }
    }

    enum MenuBarDisplay: String, CaseIterable, Identifiable {
        case iconAndPower, iconOnly, powerOnly
        var id: String { rawValue }
    }

    enum MenuBarColorMode: String, CaseIterable, Identifiable {
        case monochrome, colored
        var id: String { rawValue }
    }

    enum PowerUnit: String, CaseIterable, Identifiable {
        case automatic, kilowatts, watts
        var id: String { rawValue }
    }

    private let defaults = UserDefaults.standard

    @Published var language: Language { didSet { defaults.set(language.rawValue, forKey: "language") } }
    @Published var menuBarDisplay: MenuBarDisplay { didSet { defaults.set(menuBarDisplay.rawValue, forKey: "menuBarDisplay") } }
    @Published var menuBarColorMode: MenuBarColorMode { didSet { defaults.set(menuBarColorMode.rawValue, forKey: "menuBarColorMode") } }
    @Published var powerUnit: PowerUnit { didSet { defaults.set(powerUnit.rawValue, forKey: "powerUnit") } }
    @Published var notifyOnConnectionChange: Bool { didSet { defaults.set(notifyOnConnectionChange, forKey: "notifyOnConnectionChange") } }
    @Published var showOverview: Bool { didSet { defaults.set(showOverview, forKey: "showOverview") } }
    @Published var showTechnical: Bool { didSet { defaults.set(showTechnical, forKey: "showTechnical") } }
    @Published var showFlow: Bool { didSet { defaults.set(showFlow, forKey: "showFlow") } }
    @Published var showStatus: Bool { didSet { defaults.set(showStatus, forKey: "showStatus") } }
    @Published var refreshInterval: TimeInterval { didSet { defaults.set(refreshInterval, forKey: "refreshInterval") } }

    init() {
        language = Language(rawValue: defaults.string(forKey: "language") ?? "cs") ?? .cs
        menuBarDisplay = MenuBarDisplay(rawValue: defaults.string(forKey: "menuBarDisplay") ?? "iconAndPower") ?? .iconAndPower
        menuBarColorMode = MenuBarColorMode(rawValue: defaults.string(forKey: "menuBarColorMode") ?? "monochrome") ?? .monochrome
        powerUnit = PowerUnit(rawValue: defaults.string(forKey: "powerUnit") ?? "automatic") ?? .automatic
        notifyOnConnectionChange = defaults.object(forKey: "notifyOnConnectionChange") as? Bool ?? false
        showOverview = defaults.object(forKey: "showOverview") as? Bool ?? true
        showTechnical = defaults.object(forKey: "showTechnical") as? Bool ?? true
        showFlow = defaults.object(forKey: "showFlow") as? Bool ?? true
        showStatus = defaults.object(forKey: "showStatus") as? Bool ?? true
        refreshInterval = defaults.object(forKey: "refreshInterval") as? Double ?? 10
    }

    func text(_ cs: String, _ en: String, _ de: String? = nil, _ sk: String? = nil, _ pl: String? = nil) -> String {
        switch language {
        case .cs: return cs
        case .en: return en
        case .de: return de ?? en
        case .sk: return sk ?? cs
        case .pl: return pl ?? en
        }
    }

    func power(_ value: Double?, signed: Bool = false) -> String {
        guard let value else { return "—" }
        let prefix = signed && value > 0 ? "+" : ""
        switch powerUnit {
        case .automatic:
            if abs(value) >= 1000 { return String(format: "%@%.2f kW", prefix, value / 1000) }
            return String(format: "%@%.0f W", prefix, value)
        case .kilowatts:
            return String(format: "%@%.2f kW", prefix, value / 1000)
        case .watts:
            return String(format: "%@%.0f W", prefix, value)
        }
    }
}
