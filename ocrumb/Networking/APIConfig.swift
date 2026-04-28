import Foundation

enum APIConfig {
    static let defaultBaseURL = URL(string: "http://localhost:3000")!

    static var baseURL: URL {
        if let override = UserDefaults.standard.string(forKey: "ocrumb.baseURL"),
           let url = URL(string: override) {
            return url
        }
        return defaultBaseURL
    }
}
