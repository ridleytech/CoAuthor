import Foundation

/// Minimal client for the backend API (the `backend/` Lambda
/// scaffold or an API Gateway stage). Views/view models only reach
/// this when `BackendConfiguration.shared.useBackend` is on —
/// failures fall back to mock data at the call site.
protocol BackendClient {
    func get<Response: Decodable>(_ path: String) async throws -> Response
    func post<Response: Decodable>(
        _ path: String,
        body: some Encodable
    ) async throws -> Response
    func delete<Response: Decodable>(_ path: String) async throws -> Response
}

struct URLSessionBackendClient: BackendClient {
    private let baseURL: URL
    private let session: URLSession

    /// Nonisolated — the configured base URL is read from
    /// UserDefaults (`BackendConfiguration.configuredBaseURL`) so
    /// `URLSessionBackendClient()` works in default arguments and
    /// other nonisolated contexts.
    init(
        baseURL: URL = BackendConfiguration.configuredBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Builds a request with the stored ElevenLabs key attached —
    /// the backend forwards it as xi-api-key for provider calls.
    private func request(
        _ path: String,
        method: String,
        body: (any Encodable)? = nil
    ) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        if let key = APIKeyStore.elevenLabsKey {
            request.setValue(key, forHTTPHeaderField: "xi-api-key")
        }
        if let body {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    private func fetch<Response: Decodable>(
        _ request: URLRequest
    ) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await fetch(try request(path, method: "GET"))
    }

    func post<Response: Decodable>(
        _ path: String,
        body: some Encodable
    ) async throws -> Response {
        try await fetch(try request(path, method: "POST", body: body))
    }

    func delete<Response: Decodable>(_ path: String) async throws -> Response {
        try await fetch(try request(path, method: "DELETE"))
    }
}
