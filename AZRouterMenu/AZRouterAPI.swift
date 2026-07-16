import Foundation

actor AZRouterAPI {
    private let baseURL: URL
    private let username: String
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://azrouter.local")!, username: String = "admin") {
        self.baseURL = baseURL
        self.username = username

        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 8
        self.session = URLSession(configuration: configuration)
    }

    func loadSnapshot(password: String) async throws -> EnergySnapshot {
        let token = try await login(password: password)
        let devices = try await requestJSON(path: "/api/v1/devices", token: token)

        return EnergySnapshot(
            pvPower: number(at: [1, "inverter", "totalPvPower"], in: devices),
            inverterACPower: number(at: [1, "inverter", "totalPower"], in: devices),
            housePower: number(at: [1, "inverter", "load", "totalPower"], in: devices),
            carPower: number(at: [0, "charge", "totalPower"], in: devices),
            batteryPower: number(at: [1, "inverter", "battery", "power"], in: devices),
            batterySOC: number(at: [1, "inverter", "battery", "soc"], in: devices),
            gridPower: number(at: [1, "inverter", "totalMeter"], in: devices),
            inverterTemperature: number(at: [1, "inverter", "temperature"], in: devices),
            chargerTemperature: number(at: [0, "charge", "temperature"], in: devices),
            updatedAt: Date()
        )
    }

    private func login(password: String) async throws -> String? {
        let body: [String: Any] = [
            "data": [
                "username": username,
                "password": password
            ]
        ]

        let json = try await requestJSON(path: "/api/v1/login", method: "POST", body: body, token: nil, allowsEmptyResponse: true)
        guard let dictionary = json as? [String: Any] else { return nil }

        for key in ["token", "access_token", "accessToken", "jwt", "session"] {
            if let token = dictionary[key] as? String, !token.isEmpty {
                return token
            }
        }
        return nil
    }

    private func requestJSON(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        token: String? = nil,
        allowsEmptyResponse: Bool = false
    ) async throws -> Any {
        let url = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AZRouterMenu/1.0", forHTTPHeaderField: "User-Agent")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode)
        }
        if data.isEmpty || String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            if allowsEmptyResponse { return [:] }
            throw APIError.emptyResponse
        }

        do {
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            if allowsEmptyResponse { return [:] }
            throw APIError.invalidJSON
        }
    }

    private func number(at path: [Any], in root: Any) -> Double? {
        var current: Any = root
        for part in path {
            if let index = part as? Int {
                guard let array = current as? [Any], array.indices.contains(index) else { return nil }
                current = array[index]
            } else if let key = part as? String {
                guard let dictionary = current as? [String: Any], let value = dictionary[key] else { return nil }
                current = value
            }
        }

        if let value = current as? Double { return value }
        if let value = current as? Int { return Double(value) }
        if let value = current as? NSNumber { return value.doubleValue }
        return nil
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case emptyResponse
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Router vrátil neplatnou odpověď."
        case .httpStatus(let code):
            return "Router vrátil HTTP chybu \(code)."
        case .emptyResponse:
            return "Router vrátil prázdnou odpověď."
        case .invalidJSON:
            return "Router nevrátil očekávaná data JSON."
        }
    }
}
