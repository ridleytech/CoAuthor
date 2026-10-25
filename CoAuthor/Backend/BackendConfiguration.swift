import Foundation

/// Where feature data comes from: deterministic local mocks or the
/// backend service (the `backend/` Lambda scaffold, M12).
enum DataSourceMode: String {
    case mock
    case backend
}

/// Global switch between backend data and mock data.
///
/// View models read `BackendConfiguration.shared.useBackend` at the
/// seams where mock generators/services are consulted. Persisted in
/// UserDefaults so the choice survives launches.
@Observable
@MainActor
final class BackendConfiguration {
    static let shared = BackendConfiguration()

    private let modeKey = "coauthor.dataSourceMode"
    private let baseURLKey = "coauthor.backendBaseURL"

    /// Current data source. Defaults to `.mock`.
    var mode: DataSourceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: modeKey)
        }
    }

    /// Base URL of the backend API — the API Gateway stage in
    /// production, `http://localhost:3100` for the local runner.
    var baseURL: URL {
        didSet {
            UserDefaults.standard.set(baseURL.absoluteString, forKey: baseURLKey)
        }
    }

    /// True when feature code should prefer backend data.
    var useBackend: Bool {
        get { mode == .backend }
        set { mode = newValue ? .backend : .mock }
    }

    private init() {
        let defaults = UserDefaults.standard
        mode = DataSourceMode(
            rawValue: defaults.string(forKey: modeKey) ?? ""
        ) ?? .mock
        baseURL = URL(
            string: defaults.string(forKey: baseURLKey)
                ?? "http://localhost:3100"
        ) ?? URL(string: "http://localhost:3100")!
    }
}
