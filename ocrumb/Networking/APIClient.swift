import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var token: String?

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = fractional.date(from: string) { return date }
            if let date = plain.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(string)"
            )
        }
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    // MARK: Auth

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body = ["email_address": email, "password": password]
        return try await send(.post, "/api/v1/session", body: body, authorized: false)
    }

    func register(email: String, password: String, confirm: String) async throws -> AuthResponse {
        let body = [
            "email_address": email,
            "password": password,
            "password_confirmation": confirm
        ]
        return try await send(.post, "/api/v1/registration", body: body, authorized: false)
    }

    func signOut() async throws {
        try await sendNoContent(.delete, "/api/v1/session")
    }

    // MARK: Account

    func fetchAccount() async throws -> User {
        try await send(.get, "/api/v1/account")
    }

    // MARK: Core request machinery

    private enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    private func buildRequest(_ method: Method, _ path: String, authorized: Bool) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authorized, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func send<Response: Decodable>(
        _ method: Method,
        _ path: String,
        authorized: Bool = true
    ) async throws -> Response {
        let request = try buildRequest(method, path, authorized: authorized)
        return try await perform(request: request)
    }

    private func send<Body: Encodable, Response: Decodable>(
        _ method: Method,
        _ path: String,
        body: Body,
        authorized: Bool = true
    ) async throws -> Response {
        var request = try buildRequest(method, path, authorized: authorized)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
        return try await perform(request: request)
    }

    private func sendNoContent(_ method: Method, _ path: String, authorized: Bool = true) async throws {
        let request = try buildRequest(method, path, authorized: authorized)
        let (data, response) = try await transport(request: request)
        try validate(response: response, data: data)
    }

    private func perform<Response: Decodable>(request: URLRequest) async throws -> Response {
        let (data, response) = try await transport(request: request)
        try validate(response: response, data: data)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    private func transport(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch http.statusCode {
        case 200..<300: return
        case 401: throw APIError.unauthorized
        default:
            throw APIError.server(status: http.statusCode, message: decodeErrorMessage(from: data))
        }
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        struct ErrorBody: Decodable {
            let error: String?
            let errors: [String]?
            let message: String?
        }
        guard !data.isEmpty, let body = try? decoder.decode(ErrorBody.self, from: data) else {
            return nil
        }
        if let error = body.error { return error }
        if let errors = body.errors, !errors.isEmpty { return errors.joined(separator: ", ") }
        return body.message
    }
}
