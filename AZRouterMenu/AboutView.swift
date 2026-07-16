import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var preferences: AppPreferences

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.4"
    }

    var body: some View {
        VStack(spacing: 13) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 96, height: 96)

            Text("AZ Status")
                .font(.system(size: 24, weight: .semibold, design: .rounded))

            Text(preferences.text("Verze \(version)", "Version \(version)", "Version \(version)", "Verzia \(version)", "Wersja \(version)"))
                .foregroundStyle(.secondary)

            Text(preferences.text(
                "Neoficiální lokální klient pro monitoring výroby, spotřeby a toku energie z A-Z Routeru.",
                "An unofficial local client for monitoring production, consumption and energy flow from A-Z Router.",
                "Ein inoffizieller lokaler Client zur Anzeige von Erzeugung, Verbrauch und Energiefluss des A-Z Routers.",
                "Neoficiálny lokálny klient na monitoring výroby, spotreby a toku energie z A-Z Routera.",
                "Nieoficjalny lokalny klient do monitorowania produkcji, zużycia i przepływu energii z A-Z Routera."
            ))
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 350)

            Divider()

            VStack(spacing: 4) {
                Text(preferences.text("Vytvořil Ondřej Vlček", "Created by Ondřej Vlček", "Erstellt von Ondřej Vlček", "Vytvoril Ondřej Vlček", "Autor: Ondřej Vlček"))
                    .font(.subheadline.weight(.medium))

                Link("github.com/volfion/az-status", destination: URL(string: "https://github.com/volfion/az-status")!)
                    .font(.caption)
            }

            Text(preferences.text(
                "Data zůstávají v místní síti. Heslo je uloženo v Klíčence macOS.",
                "Data stays on your local network. The password is stored in macOS Keychain.",
                "Die Daten bleiben im lokalen Netzwerk. Das Passwort wird im macOS-Schlüsselbund gespeichert.",
                "Dáta zostávajú v miestnej sieti. Heslo je uložené v Kľúčenke macOS.",
                "Dane pozostają w sieci lokalnej. Hasło jest przechowywane w pęku kluczy macOS."
            ))
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 350)

            Text(preferences.text(
                "Tento komunitní projekt není oficiálním produktem ani není podporován společností A-Z TRADERS s.r.o.",
                "This community project is not an official product of, nor endorsed by, A-Z TRADERS s.r.o.",
                "Dieses Community-Projekt ist kein offizielles Produkt von A-Z TRADERS s.r.o. und wird von diesem Unternehmen nicht unterstützt.",
                "Tento komunitný projekt nie je oficiálnym produktom ani nie je podporovaný spoločnosťou A-Z TRADERS s.r.o.",
                "Ten projekt społecznościowy nie jest oficjalnym produktem ani nie jest wspierany przez A-Z TRADERS s.r.o."
            ))
            .font(.caption2)
            .multilineTextAlignment(.center)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: 360)

            Text("© 2026 Ondřej Vlček · MIT License")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(26)
        .frame(width: 440, height: 500)
    }
}
