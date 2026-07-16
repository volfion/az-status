import SwiftUI
import AppKit
import Combine
import UserNotifications

@main
struct AZStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let preferences = AppPreferences()
    let monitor = EnergyMonitor()

    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var previousConnectionWasOnline: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        monitor.refreshInterval = preferences.refreshInterval

        preferences.$refreshInterval
            .sink { [weak self] value in self?.monitor.refreshInterval = value }
            .store(in: &cancellables)

        preferences.$notifyOnConnectionChange
            .sink { enabled in
                if enabled {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
                }
            }
            .store(in: &cancellables)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageLeading
        }

        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: DashboardView()
                .environmentObject(monitor)
                .environmentObject(preferences)
        )

        monitor.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.updateStatusItem(state)
                self?.handleConnectionNotification(state)
            }
            .store(in: &cancellables)

        // Každá změna nastavení se projeví okamžitě. objectWillChange se vysílá
        // ještě před zápisem nové hodnoty, proto aktualizaci přesuneme na další
        // průchod hlavní smyčky, kdy už jsou nové preference dostupné.
        preferences.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.updateStatusItem(self.monitor.state)
                    self.monitor.refresh()
                }
            }
            .store(in: &cancellables)

        updateStatusItem(monitor.state)
    }

    @objc private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent, let button = statusItem.button else { return }
        if event.type == .rightMouseUp {
            showContextMenu(from: button)
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateStatusItem(_ state: EnergyState) {
        guard let button = statusItem?.button else { return }
        let showIcon = preferences.menuBarDisplay != .powerOnly
        let showPower = preferences.menuBarDisplay != .iconOnly

        if showIcon {
            let base = NSImage(systemSymbolName: state.menuBarSymbol, accessibilityDescription: state.accessibilityLabel)
            if preferences.menuBarColorMode == .monochrome {
                base?.isTemplate = true
                button.image = base
            } else {
                base?.isTemplate = false
                let color: NSColor
                switch state.connection {
                case .offline: color = .systemRed
                case .loading: color = .systemGray
                case .online: color = state.isProducing ? .systemYellow : .systemIndigo
                }
                button.image = base?.withSymbolConfiguration(.init(paletteColors: [color]))
            }
        } else {
            button.image = nil
        }

        button.title = showPower ? " \(menuPowerText(state))" : ""
        button.toolTip = "AZ Status"
    }

    private func menuPowerText(_ state: EnergyState) -> String {
        switch state.connection {
        case .offline: return "FVE"
        case .loading: return "…"
        case .online: return preferences.power(state.snapshot.pvPower)
        }
    }

    private func showContextMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()
        addMenuItem(to: menu, title: t("Nastavení…", "Settings…", "Einstellungen…", "Nastavenia…", "Ustawienia…"), symbol: "gearshape", action: #selector(openSettings), key: ",")
        addMenuItem(to: menu, title: t("O aplikaci AZ Status", "About AZ Status", "Über AZ Status", "O aplikácii AZ Status", "O aplikacji AZ Status"), symbol: "info.circle", action: #selector(openAbout))
        menu.addItem(.separator())
        addMenuItem(to: menu, title: t("Ukončit AZ Status", "Quit AZ Status", "AZ Status beenden", "Ukončiť AZ Status", "Zakończ AZ Status"), symbol: "power", action: #selector(quitApp), key: "q")
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    private func addMenuItem(to menu: NSMenu, title: String, symbol: String, action: Selector, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        menu.addItem(item)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView().environmentObject(monitor).environmentObject(preferences)
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        settingsWindow?.title = t("Nastavení AZ Status", "AZ Status Settings", "AZ Status Einstellungen", "Nastavenia AZ Status", "Ustawienia AZ Status")
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func openAbout() {
        if aboutWindow == nil {
            let view = AboutView().environmentObject(preferences)
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            aboutWindow = window
        }
        aboutWindow?.title = t("O aplikaci AZ Status", "About AZ Status", "Über AZ Status", "O aplikácii AZ Status", "O aplikacji AZ Status")
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow?.makeKeyAndOrderFront(nil)
    }

    private func handleConnectionNotification(_ state: EnergyState) {
        let online: Bool
        switch state.connection {
        case .online: online = true
        case .offline: online = false
        case .loading: return
        }
        defer { previousConnectionWasOnline = online }
        guard preferences.notifyOnConnectionChange, let previous = previousConnectionWasOnline, previous != online else { return }

        let content = UNMutableNotificationContent()
        content.title = "AZ Status"
        content.body = online
            ? t("Spojení s A-Z Routerem bylo obnoveno.", "Connection to A-Z Router was restored.", "Die Verbindung zum A-Z Router wurde wiederhergestellt.", "Spojenie s A-Z Routerom bolo obnovené.", "Połączenie z A-Z Routerem zostało przywrócone.")
            : t("A-Z Router přestal odpovídat.", "A-Z Router stopped responding.", "Der A-Z Router antwortet nicht mehr.", "A-Z Router prestal odpovedať.", "A-Z Router przestał odpowiadać.")
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    private func t(_ cs: String, _ en: String, _ de: String, _ sk: String, _ pl: String) -> String {
        preferences.text(cs, en, de, sk, pl)
    }

    @objc private func quitApp() { NSApp.terminate(nil) }
}
