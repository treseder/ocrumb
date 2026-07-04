import Foundation
import Testing
@testable import ocrumb

/// Nested inside `StubbedNetworkTests` (see `SessionStoreTests`) so the
/// delete flows never race other suites over the global stub.
extension StubbedNetworkTests {
    @MainActor
    struct SettingsViewModelTests {

        private func makeSession() -> SessionStore {
            let api = APIClient(session: StubURLProtocol.makeSession())
            return SessionStore(api: api, keychain: InMemoryTokenStore(token: "stored-token"))
        }

        @Test func cannotDeleteWithoutPassword() {
            let model = SettingsViewModel()
            #expect(model.canDelete == false)
            model.deletePassword = "hunter2"
            #expect(model.canDelete == true)
        }

        @Test func deleteWithoutPasswordDoesNothing() async {
            let model = SettingsViewModel()
            StubURLProtocol.reset()

            await model.deleteAccount(using: makeSession())

            // No request was attempted, so no error either.
            #expect(StubURLProtocol.lastRequest == nil)
            #expect(model.errorMessage == nil)
        }

        @Test func wrongPasswordSurfacesErrorAndClearsField() async {
            let model = SettingsViewModel()
            model.deletePassword = "wrong"
            StubURLProtocol.setResponse(status: 403, json: #"{"error": "Incorrect password"}"#)

            await model.deleteAccount(using: makeSession())

            #expect(model.errorMessage == "Incorrect password")
            #expect(model.deletePassword.isEmpty)
            #expect(model.isDeleting == false)
        }

        @Test func successfulDeleteSignsSessionOut() async {
            let model = SettingsViewModel()
            model.deletePassword = "hunter2"
            let session = makeSession()
            StubURLProtocol.setResponse(status: 204, json: "")

            await model.deleteAccount(using: session)

            #expect(model.errorMessage == nil)
            if case .signedOut = session.state {
                // expected
            } else {
                Issue.record("expected session to be signed out")
            }
        }
    }
}
