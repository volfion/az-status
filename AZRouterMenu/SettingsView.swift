import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var monitor: EnergyMonitor
    @EnvironmentObject private var preferences: AppPreferences
    @State private var password = ""
    @State private var message = ""
    @State private var isError = false

    var body: some View {
        Form {
            Section(t("Obecné", "General", "Allgemein", "Všeobecné", "Ogólne")) {
                Picker(t("Jazyk", "Language", "Sprache", "Jazyk", "Język"), selection: $preferences.language) {
                    ForEach(AppPreferences.Language.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(t("Menu bar", "Menu bar", "Menüleiste", "Panel ponuky", "Pasek menu")) {
                Picker(t("Zobrazení", "Display", "Anzeige", "Zobrazenie", "Wyświetlanie"), selection: $preferences.menuBarDisplay) {
                    Text(t("Ikona a výkon", "Icon and power", "Symbol und Leistung", "Ikona a výkon", "Ikona i moc")).tag(AppPreferences.MenuBarDisplay.iconAndPower)
                    Text(t("Pouze ikona", "Icon only", "Nur Symbol", "Iba ikona", "Tylko ikona")).tag(AppPreferences.MenuBarDisplay.iconOnly)
                    Text(t("Pouze výkon", "Power only", "Nur Leistung", "Iba výkon", "Tylko moc")).tag(AppPreferences.MenuBarDisplay.powerOnly)
                }
                .pickerStyle(.menu)

                Picker(t("Barevné stavy", "Status colors", "Statusfarben", "Farebné stavy", "Kolory statusu"), selection: $preferences.menuBarColorMode) {
                    Text(t("Bílé", "Monochrome", "Einfarbig", "Biele", "Białe")).tag(AppPreferences.MenuBarColorMode.monochrome)
                    Text(t("Barevné", "Colored", "Farbig", "Farebné", "Kolorowe")).tag(AppPreferences.MenuBarColorMode.colored)
                }
                .pickerStyle(.menu)

                Picker(t("Jednotky výkonu", "Power units", "Leistungseinheiten", "Jednotky výkonu", "Jednostki mocy"), selection: $preferences.powerUnit) {
                    Text(t("Automaticky", "Automatic", "Automatisch", "Automaticky", "Automatycznie")).tag(AppPreferences.PowerUnit.automatic)
                    Text("kW").tag(AppPreferences.PowerUnit.kilowatts)
                    Text("W").tag(AppPreferences.PowerUnit.watts)
                }
                .pickerStyle(.menu)
            }

            Section(t("Zobrazené sekce", "Visible sections", "Sichtbare Bereiche", "Zobrazené sekcie", "Widoczne sekcje")) {
                Toggle(t("Přehled výroby a spotřeby", "Production and consumption overview", "Übersicht Erzeugung und Verbrauch", "Prehľad výroby a spotreby", "Przegląd produkcji i zużycia"), isOn: $preferences.showOverview)
                Toggle(t("Technické informace a teploty", "Technical information and temperatures", "Technische Daten und Temperaturen", "Technické informácie a teploty", "Dane techniczne i temperatury"), isOn: $preferences.showTechnical)
                Toggle(t("Graf toku energie", "Energy flow diagram", "Energieflussdiagramm", "Graf toku energie", "Diagram przepływu energii"), isOn: $preferences.showFlow)
                Toggle(t("Stav, odkazy a automatické spuštění", "Status, links and launch at login", "Status, Links und Autostart", "Stav, odkazy a automatické spustenie", "Status, linki i autostart"), isOn: $preferences.showStatus)
            }

            Section(t("Aktualizace", "Refresh", "Aktualisierung", "Aktualizácia", "Odświeżanie")) {
                Picker(t("Interval aktualizace", "Refresh interval", "Aktualisierungsintervall", "Interval aktualizácie", "Interwał odświeżania"), selection: $preferences.refreshInterval) {
                    Text(t("5 sekund", "5 seconds", "5 Sekunden", "5 sekúnd", "5 sekund")).tag(5.0)
                    Text(t("10 sekund", "10 seconds", "10 Sekunden", "10 sekúnd", "10 sekund")).tag(10.0)
                    Text(t("30 sekund", "30 seconds", "30 Sekunden", "30 sekúnd", "30 sekund")).tag(30.0)
                    Text(t("1 minuta", "1 minute", "1 Minute", "1 minúta", "1 minuta")).tag(60.0)
                    Text(t("5 minut", "5 minutes", "5 Minuten", "5 minút", "5 minut")).tag(300.0)
                }
                .pickerStyle(.menu)
                Toggle(t("Upozornit při výpadku a obnovení spojení", "Notify on connection loss and recovery", "Bei Verbindungsverlust und Wiederherstellung benachrichtigen", "Upozorniť pri výpadku a obnovení spojenia", "Powiadamiaj o utracie i odzyskaniu połączenia"), isOn: $preferences.notifyOnConnectionChange)
            }

            Section(t("Připojení", "Connection", "Verbindung", "Pripojenie", "Połączenie")) {
                LabeledContent(t("Adresa", "Address", "Adresse", "Adresa", "Adres"), value: "http://azrouter.local")
                LabeledContent(t("Uživatel", "User", "Benutzer", "Používateľ", "Użytkownik"), value: "admin")
                SecureField(t("Lokální heslo", "Local password", "Lokales Passwort", "Lokálne heslo", "Hasło lokalne"), text: $password)
                Button(t("Uložit heslo do Klíčenky", "Save password to Keychain", "Passwort im Schlüsselbund speichern", "Uložiť heslo do Kľúčenky", "Zapisz hasło w pęku kluczy")) { savePassword() }
            }

            if !message.isEmpty {
                Text(message).foregroundStyle(isError ? .red : .green)
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 690)
        .padding()
    }

    private func t(_ cs: String, _ en: String, _ de: String? = nil, _ sk: String? = nil, _ pl: String? = nil) -> String {
        preferences.text(cs, en, de, sk, pl)
    }

    private func savePassword() {
        guard !password.isEmpty else {
            isError = true
            message = t("Zadej heslo.", "Enter a password.", "Passwort eingeben.", "Zadaj heslo.", "Wpisz hasło.")
            return
        }
        do {
            try monitor.savePassword(password)
            password = ""
            isError = false
            message = t("Heslo bylo bezpečně uloženo do Klíčenky.", "The password was securely saved to Keychain.", "Das Passwort wurde sicher im Schlüsselbund gespeichert.", "Heslo bolo bezpečne uložené do Kľúčenky.", "Hasło zostało bezpiecznie zapisane w pęku kluczy.")
        } catch {
            isError = true
            message = error.localizedDescription
        }
    }
}
