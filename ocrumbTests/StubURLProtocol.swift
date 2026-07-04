import Foundation

/// A `URLProtocol` that intercepts every request and replies with queued
/// stubs, so `APIClient` can be exercised end-to-end without a network.
/// Responses are served in order; the last one repeats once the queue is
/// down to a single entry (so polling that re-fetches keeps getting it).
/// State is global, so suites using it must run `.serialized`.
final class StubURLProtocol: URLProtocol {
    struct Stub {
        var statusCode: Int
        var data: Data
        var headers: [String: String] = ["Content-Type": "application/json"]
    }

    nonisolated(unsafe) private static var _queue: [Stub] = []
    nonisolated(unsafe) private static var _lastRequest: URLRequest?
    nonisolated(unsafe) private static var _lastRequestBody: Data?
    private static let lock = NSLock()

    /// Builds a session whose only protocol is the stub.
    nonisolated static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    nonisolated static func setStub(_ stub: Stub) {
        lock.lock(); defer { lock.unlock() }
        _queue = [stub]
        _lastRequest = nil
        _lastRequestBody = nil
    }

    /// Convenience for a single JSON body + status code.
    nonisolated static func setResponse(status: Int, json: String) {
        setStub(Stub(statusCode: status, data: Data(json.utf8)))
    }

    /// Queues a sequence of JSON responses, consumed one per request.
    nonisolated static func setResponses(_ responses: [(status: Int, json: String)]) {
        lock.lock(); defer { lock.unlock() }
        _queue = responses.map { Stub(statusCode: $0.status, data: Data($0.json.utf8)) }
        _lastRequest = nil
        _lastRequestBody = nil
    }

    nonisolated static var lastRequest: URLRequest? {
        lock.lock(); defer { lock.unlock() }
        return _lastRequest
    }

    /// `URLSession` hands protocols the body as a stream, so `lastRequest`'s
    /// `httpBody` is always nil — this captures the drained stream instead.
    nonisolated static var lastRequestBody: Data? {
        lock.lock(); defer { lock.unlock() }
        return _lastRequestBody
    }

    nonisolated static func reset() {
        lock.lock(); defer { lock.unlock() }
        _queue = []
        _lastRequest = nil
        _lastRequestBody = nil
    }

    nonisolated override class func canInit(with request: URLRequest) -> Bool { true }

    nonisolated override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    nonisolated override func startLoading() {
        let body = Self.readBody(of: request)
        StubURLProtocol.lock.lock()
        StubURLProtocol._lastRequest = request
        StubURLProtocol._lastRequestBody = body
        let stub: Stub?
        if StubURLProtocol._queue.count > 1 {
            stub = StubURLProtocol._queue.removeFirst()
        } else {
            stub = StubURLProtocol._queue.first
        }
        StubURLProtocol.lock.unlock()

        guard let stub, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: stub.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: stub.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    nonisolated override func stopLoading() {}

    nonisolated private static func readBody(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
