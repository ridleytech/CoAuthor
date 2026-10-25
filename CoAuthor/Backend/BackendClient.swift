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

    @MainActor
    init(
        baseURL: URL = BackendConfiguration.shared.baseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<Response: Decodable>(_ path: String) async throws -> Response {
        let url = baseURL.appendingPathComponent(path)
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    func post<Response: Decodable>(
        _ path: String,
        body: some Encodable
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    func delete<Response: Decodable>(_ path: String) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
