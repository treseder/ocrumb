import Foundation

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case server(status: Int, message: String?)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .invalidResponse: return "Unexpected response from server."
        case .unauthorized: return "Your session has expired. Please sign in again."
        case .server(_, let message): return message ?? "Server error."
        case .decoding(let detail): return "Couldn't read server response. \(detail)"
        case .transport(let detail): return detail
        }
    }
}
