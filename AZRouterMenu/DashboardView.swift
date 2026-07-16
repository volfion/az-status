import SwiftUI
import AppKit
import ServiceManagement

struct DashboardView: View {
    @EnvironmentObject private var monitor: EnergyMonitor
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.openURL) private var openURL
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginMessage: String?

    private let localURL = URL(string: "http://azrouter.local")!
    private let cloudURL = URL(string: "https://new.azrouter.cloud")!

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if preferences.showOverview || preferences.showTechnical {
                overview
                Divider()
            }
            if preferences.showFlow {
                flowSection
                Divider()
            }
            if preferences.showStatus {
                footer
            }
        }
        .frame(width: 590)
        .background(.ultraThinMaterial)
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(headerColor.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: monitor.state.menuBarSymbol)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(headerColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("AZ Status")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(headerSubtitle)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            Spacer()

            Button {
                monitor.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .help(t("Obnovit nyní", "Refresh now", "Jetzt aktualisieren", "Obnoviť teraz", "Odśwież teraz"))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var overview: some View {
        HStack(alignment: .top, spacing: 18) {
            if preferences.showOverview {
                VStack(spacing: 9) {
                    DashboardRow(icon: "sun.max.fill", color: .yellow, title: t("Výroba FVE", "PV production", "PV-Erzeugung", "Výroba FVE", "Produkcja PV"), value: preferences.power(snapshot.pvPower))
                    DashboardRow(icon: "house.fill", color: .blue, title: t("Spotřeba domu", "Home consumption", "Hausverbrauch", "Spotreba domu", "Zużycie domu"), value: preferences.power(snapshot.housePower))
                    DashboardRow(icon: "car.fill", color: .purple, title: t("Nabíjení auta", "Car charging", "Autoladung", "Nabíjanie auta", "Ładowanie auta"), value: preferences.power(snapshot.carPower))
                    DashboardRow(icon: batterySymbol, color: batteryColor, title: t("Baterie", "Battery", "Batterie", "Batéria", "Bateria"), value: batteryText)
                    DashboardRow(icon: gridSymbol, color: gridColor, title: gridTitle, value: gridText)
                }
                .frame(maxWidth: .infinity)
            }

            if preferences.showOverview && preferences.showTechnical { Divider() }

            if preferences.showTechnical {
                VStack(spacing: 9) {
                    DashboardRow(icon: "waveform.path.ecg", color: .secondary, title: t("Výstup střídače", "Inverter output", "Wechselrichterleistung", "Výstup meniča", "Moc falownika"), value: preferences.power(snapshot.inverterACPower))
                    DashboardRow(icon: "thermometer.medium", color: inverterTemperatureColor, title: t("Teplota střídače", "Inverter temperature", "Wechselrichtertemperatur", "Teplota meniča", "Temperatura falownika"), value: TemperatureFormatter.string(snapshot.inverterTemperature))
                    DashboardRow(icon: "thermometer.medium", color: chargerTemperatureColor, title: t("Teplota nabíječky", "Charger temperature", "Ladegerättemperatur", "Teplota nabíjačky", "Temperatura ładowarki"), value: TemperatureFormatter.string(snapshot.chargerTemperature))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
    }

    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t("TOK ENERGIE", "ENERGY FLOW", "ENERGIEFLUSS", "TOK ENERGIE", "PRZEPŁYW ENERGII"))
                .font(.caption.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(.secondary)

            EnergyFlowDiagram(
                pvPower: snapshot.pvPower,
                housePower: snapshot.housePower,
                carPower: snapshot.carPower,
                batteryPower: snapshot.batteryPower,
                batterySOC: snapshot.batterySOC,
                gridPower: snapshot.gridPower
            )
        }
        .padding(18)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Label(connectionText, systemImage: connectionSymbol)
                    .foregroundStyle(connectionColor)
                Spacer()
                Label(updatedText, systemImage: "clock")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            if let launchAtLoginMessage {
                Text(launchAtLoginMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Button {
                    openURL(localURL)
                } label: {
                    Label(t("Otevřít A-Z Router", "Open A-Z Router", "A-Z Router öffnen", "Otvoriť A-Z Router", "Otwórz A-Z Router"), systemImage: "globe")
                }

                Button {
                    openURL(cloudURL)
                } label: {
                    Label(t("Otevřít Cloud", "Open Cloud", "Cloud öffnen", "Otvoriť Cloud", "Otwórz chmurę"), systemImage: "cloud")
                }

                Spacer()

                Button(role: .destructive) {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label(t("Ukončit AZ Status", "Quit AZ Status", "AZ Status beenden", "Ukončiť AZ Status", "Zakończ AZ Status"), systemImage: "power")
                }
            }
            .buttonStyle(.borderless)

            Toggle(t("Spouštět po přihlášení", "Launch at login", "Beim Anmelden starten", "Spúšťať po prihlásení", "Uruchamiaj po zalogowaniu"), isOn: Binding(
                get: { launchAtLogin },
                set: { setLaunchAtLogin($0) }
            ))
            .toggleStyle(.switch)
            .font(.caption)
        }
        .padding(18)
    }

    private func t(_ cs: String, _ en: String, _ de: String? = nil, _ sk: String? = nil, _ pl: String? = nil) -> String { preferences.text(cs, en, de, sk, pl) }

    private var snapshot: EnergySnapshot { monitor.state.snapshot }

    private var headerSubtitle: String {
        switch monitor.state.connection {
        case .loading: return t("Načítání…", "Loading…", "Wird geladen…", "Načítanie…", "Ładowanie…")
        case .offline: return "Offline"
        case .online: return preferences.power(snapshot.pvPower)
        }
    }

    private var headerColor: Color {
        switch monitor.state.connection {
        case .offline: return .red
        case .loading: return .secondary
        case .online: return monitor.state.isProducing ? .yellow : .indigo
        }
    }

    private var batteryText: String {
        let power = preferences.power(snapshot.batteryPower, signed: true)
        guard let soc = snapshot.batterySOC else { return power }
        return "\(String(format: "%.0f", soc)) %  •  \(power)"
    }

    private var batterySymbol: String {
        guard let soc = snapshot.batterySOC else { return "battery.0" }
        switch soc {
        case 75...: return "battery.100"
        case 40..<75: return "battery.50"
        case 15..<40: return "battery.25"
        default: return "battery.0"
        }
    }

    private var batteryColor: Color {
        guard let soc = snapshot.batterySOC else { return .secondary }
        if soc < 15 { return .red }
        if (snapshot.batteryPower ?? 0) > 20 { return .green }
        if (snapshot.batteryPower ?? 0) < -20 { return .blue }
        return .secondary
    }

    private var gridTitle: String {
        guard let grid = snapshot.gridPower else { return t("Síť", "Grid", "Netz", "Sieť", "Sieć") }
        if grid > 20 { return t("Přetok do sítě", "Export to grid", "Netzeinspeisung", "Pretok do siete", "Eksport do sieci") }
        if grid < -20 { return t("Odběr ze sítě", "Import from grid", "Netzbezug", "Odber zo siete", "Pobór z sieci") }
        return t("Síť", "Grid", "Netz", "Sieť", "Sieć")
    }

    private var gridText: String {
        guard let grid = snapshot.gridPower else { return "—" }
        return preferences.power(abs(grid))
    }

    private var gridSymbol: String {
        guard let grid = snapshot.gridPower else { return "bolt.horizontal" }
        if grid > 20 { return "arrow.up.right.circle.fill" }
        if grid < -20 { return "arrow.down.left.circle.fill" }
        return "equal.circle.fill"
    }

    private var gridColor: Color {
        guard let grid = snapshot.gridPower else { return .secondary }
        if grid > 20 { return .green }
        if grid < -20 { return .red }
        return .secondary
    }

    private var inverterTemperatureColor: Color {
        temperatureColor(snapshot.inverterTemperature, warning: 65, critical: 75)
    }

    private var chargerTemperatureColor: Color {
        temperatureColor(snapshot.chargerTemperature, warning: 55, critical: 70)
    }

    private func temperatureColor(_ value: Double?, warning: Double, critical: Double) -> Color {
        guard let value else { return .secondary }
        if value >= critical { return .red }
        if value >= warning { return .orange }
        return .yellow
    }

    private var connectionText: String {
        switch monitor.state.connection {
        case .loading: return t("Načítání", "Loading", "Wird geladen", "Načítanie", "Ładowanie")
        case .online: return t("Lokální spojení aktivní", "Local connection active", "Lokale Verbindung aktiv", "Lokálne spojenie aktívne", "Połączenie lokalne aktywne")
        case .offline(let message): return message
        }
    }

    private var connectionSymbol: String {
        switch monitor.state.connection {
        case .loading: return "arrow.triangle.2.circlepath"
        case .online: return "checkmark.circle.fill"
        case .offline: return "exclamationmark.triangle.fill"
        }
    }

    private var connectionColor: Color {
        switch monitor.state.connection {
        case .loading: return .secondary
        case .online: return .green
        case .offline: return .red
        }
    }

    private var updatedText: String {
        guard let date = snapshot.updatedAt else { return t("Neaktualizováno", "Not updated", "Nicht aktualisiert", "Neaktualizované", "Nie zaktualizowano") }
        return t("Aktualizováno", "Updated", "Aktualisiert", "Aktualizované", "Zaktualizowano") + " " + date.formatted(date: .omitted, time: .standard)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchAtLoginMessage = nil
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchAtLoginMessage = t("Automatické spuštění se nepodařilo nastavit: ", "Could not configure launch at login: ", "Autostart konnte nicht eingerichtet werden: ", "Automatické spustenie sa nepodarilo nastaviť: ", "Nie udało się ustawić autostartu: ") + error.localizedDescription
        }
    }
}

private struct DashboardRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}

private struct EnergyFlowDiagram: View {
    @EnvironmentObject private var preferences: AppPreferences
    let pvPower: Double?
    let housePower: Double?
    let carPower: Double?
    let batteryPower: Double?
    let batterySOC: Double?
    let gridPower: Double?

    var body: some View {
        ZStack {
            FlowConnector(symbol: "arrow.down", color: .yellow, active: (pvPower ?? 0) > 20)
                .offset(y: -45)

            FlowConnector(symbol: batteryArrow, color: batteryColor, active: abs(batteryPower ?? 0) > 20)
                .offset(x: -82)

            FlowConnector(symbol: gridArrow, color: gridColor, active: abs(gridPower ?? 0) > 20)
                .offset(x: 82)

            FlowConnector(symbol: "arrow.down", color: .purple, active: (carPower ?? 0) > 20)
                .offset(y: 45)

            FlowNode(symbol: "sun.max.fill", value: preferences.power(pvPower), color: .yellow)
                .offset(y: -92)

            FlowNode(symbol: batterySymbol, value: batteryValue, color: batteryColor)
                .offset(x: -165)

            FlowNode(symbol: "house.fill", value: preferences.power(housePower), color: .blue)

            FlowNode(symbol: "transmission", value: gridValue, color: gridColor)
                .offset(x: 165)

            FlowNode(symbol: "car.fill", value: preferences.power(carPower), color: .purple)
                .offset(y: 92)
        }
        .frame(height: 230)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var batteryValue: String {
        if let soc = batterySOC {
            return "\(String(format: "%.0f", soc)) %\n\(preferences.power(batteryPower, signed: true))"
        }
        return preferences.power(batteryPower, signed: true)
    }

    private var gridValue: String {
        guard let gridPower else { return "—" }
        return preferences.power(abs(gridPower))
    }

    private var batterySymbol: String {
        guard let soc = batterySOC else { return "battery.0" }
        switch soc {
        case 75...: return "battery.100"
        case 40..<75: return "battery.50"
        case 15..<40: return "battery.25"
        default: return "battery.0"
        }
    }

    private var batteryColor: Color {
        guard let soc = batterySOC else { return .secondary }
        if soc < 15 { return .red }
        if (batteryPower ?? 0) > 20 { return .green }
        if (batteryPower ?? 0) < -20 { return .blue }
        return .secondary
    }

    private var gridColor: Color {
        guard let gridPower else { return .secondary }
        if gridPower > 20 { return .green }
        if gridPower < -20 { return .red }
        return .secondary
    }

    private var batteryArrow: String {
        guard let batteryPower else { return "arrow.left.and.right" }
        if batteryPower > 20 { return "arrow.right" }
        if batteryPower < -20 { return "arrow.left" }
        return "arrow.left.and.right"
    }

    private var gridArrow: String {
        guard let gridPower else { return "arrow.left.and.right" }
        if gridPower > 20 { return "arrow.right" }
        if gridPower < -20 { return "arrow.left" }
        return "arrow.left.and.right"
    }
}

private struct FlowNode: View {
    let symbol: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .foregroundStyle(color)
        }
        .frame(width: 92, height: 64)
    }
}

private struct FlowConnector: View {
    let symbol: String
    let color: Color
    let active: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 19, weight: .bold))
            .foregroundStyle(active ? color : Color.secondary.opacity(0.25))
    }
}
