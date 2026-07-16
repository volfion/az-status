import Foundation

@MainActor
final class EnergyMonitor: ObservableObject {
    @Published private(set) var state = EnergyState()
    @Published var refreshInterval: TimeInterval = 10 {
        didSet { restartTimer() }
    }

    private let api = AZRouterAPI()
    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?

    init() {
        restartTimer()
        refresh()
    }

    deinit {
        timer?.invalidate()
        refreshTask?.cancel()
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            if case .online = state.connection {
                // Při běžném obnovení ponecháme poslední data zobrazená.
            } else {
                state.connection = .loading
            }

            do {
                let password = try KeychainStore.readPassword()
                let snapshot = try await api.loadSnapshot(password: password)
                guard !Task.isCancelled else { return }
                state = EnergyState(connection: .online, snapshot: snapshot)
            } catch {
                guard !Task.isCancelled else { return }
                state.connection = .offline(error.localizedDescription)
            }
        }
    }

    func savePassword(_ password: String) throws {
        try KeychainStore.savePassword(password)
        refresh()
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: max(5, refreshInterval), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        timer?.tolerance = 1
    }
}
