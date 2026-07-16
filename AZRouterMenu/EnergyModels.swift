import Foundation
import SwiftUI

enum ConnectionStatus: Equatable {
    case loading
    case online
    case offline(String)
}

struct EnergySnapshot: Equatable {
    var pvPower: Double?
    var inverterACPower: Double?
    var housePower: Double?
    var carPower: Double?
    var batteryPower: Double?
    var batterySOC: Double?
    var gridPower: Double?
    var inverterTemperature: Double?
    var chargerTemperature: Double?
    var updatedAt: Date?
}

struct EnergyState: Equatable {
    var connection: ConnectionStatus = .loading
    var snapshot = EnergySnapshot()

    var isProducing: Bool {
        (snapshot.pvPower ?? 0) > 20
    }

    var menuBarSymbol: String {
        switch connection {
        case .offline:
            return "exclamationmark.triangle"
        case .loading:
            return "arrow.triangle.2.circlepath"
        case .online:
            return isProducing ? "sun.max" : "moon"
        }
    }

    var menuBarText: String {
        switch connection {
        case .offline:
            return "FVE"
        case .loading:
            return "…"
        case .online:
            return PowerFormatter.string(snapshot.pvPower)
        }
    }

    var accessibilityLabel: String {
        switch connection {
        case .loading:
            return "A-Z Router načítá data"
        case .offline(let message):
            return "A-Z Router je offline. \(message)"
        case .online:
            return "Výkon fotovoltaiky \(PowerFormatter.string(snapshot.pvPower))"
        }
    }
}

enum PowerFormatter {
    static func string(_ value: Double?, signed: Bool = false) -> String {
        guard let value else { return "—" }
        let prefix = signed && value > 0 ? "+" : ""
        if abs(value) >= 1000 {
            return String(format: "%@%.2f kW", prefix, value / 1000)
        }
        return String(format: "%@%.0f W", prefix, value)
    }
}

enum TemperatureFormatter {
    static func string(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f °C", value)
    }
}
