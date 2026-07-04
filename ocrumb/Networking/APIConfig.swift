import Foundation

enum APIConfig {
    /// The deployed backend — web and API share one Rails host. If the
    /// production domain changes, this is the only line to update.
    static let productionBaseURL = URL(string: "https://ocrumb.com")!

    #if DEBUG
    /// Debug builds target a local backend, overridable without recompiling
    /// via the `ocrumb.baseURL` UserDefaults key (e.g. a scheme launch
    /// argument: `-ocrumb.baseURL https://staging.example.com`).
    static var baseURL: URL {
        if let override = UserDefaults.standard.string(forKey: "ocrumb.baseURL"),
           let url = URL(string: override) {
            return url
        }
        return URL(string: "http://localhost:3000")!
    }
    #else
    static var baseURL: URL { productionBaseURL }
    #endif
}
