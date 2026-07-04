import Foundation
import Testing
@testable import ocrumb

/// Nested inside `StubbedNetworkTests` so it inherits `.serialized` and never
/// races with `APIClientTests` over the global stub. Covers the auth-state
/// transitions and the token-retention rules in `SessionStore.bootstrap`.
extension StubbedNetworkTests {
    @MainActor
    struct SessionStoreTests {

        private func makeStore(token: String?) -> (SessionStore, InMemoryTokenStore) {
            let keychain = InMemoryTokenStore(token: token)
            let api = APIClient(session: StubURLProtocol.makeSession())
            return (SessionStore(api: api, keychain: keychain), keychain)
        }

        @Test func bootstrapWithoutTokenSignsOut() async {
            let (session, _) = makeStore(token: nil)
            await session.bootstrap()
            #expect(isSignedOut(session.state))
        }

        @Test func bootstrapWithValidTokenSignsIn() async {
            let (session, keychain) = makeStore(token: "stored-token")
            StubURLProtocol.setResponse(status: 200, json: Fixtures.user)

            await session.bootstrap()

            #expect(signedInUser(session.state)?.emailAddress == "cook@example.com")
            #expect(keychain.token == "stored-token")
        }

        @Test func bootstrapWithUnauthorizedClearsToken() async {
            let (session, keychain) = makeStore(token: "stale-token")
            StubURLProtocol.setResponse(status: 401, json: "")

            await session.bootstrap()

            #expect(isSignedOut(session.state))
            #expect(keychain.token == nil)
        }

        @Test func bootstrapWithServerErrorPreservesToken() async {
            let (session, keychain) = makeStore(token: "stored-token")
            StubURLProtocol.setResponse(status: 500, json: "{}")

            await session.bootstrap()

            // Transient failure: sign out for now, but keep the token to retry.
            #expect(isSignedOut(session.state))
            #expect(keychain.token == "stored-token")
        }

        @Test func signInPersistsTokenAndSignsIn() async throws {
            let (session, keychain) = makeStore(token: nil)
            StubURLProtocol.setResponse(status: 200, json: Fixtures.authResponse)

            try await session.signIn(email: "cook@example.com", password: "secret")

            #expect(signedInUser(session.state)?.isPro == true)
            #expect(keychain.token == "test-token-123")
        }

        @Test func deleteAccountClearsTokenAndSignsOut() async throws {
            let (session, keychain) = makeStore(token: "stored-token")
            StubURLProtocol.setResponse(status: 200, json: Fixtures.user)
            await session.bootstrap()
            StubURLProtocol.setResponse(status: 204, json: "")

            try await session.deleteAccount(password: "hunter2")

            #expect(isSignedOut(session.state))
            #expect(keychain.token == nil)
        }

        @Test func deleteAccountWithWrongPasswordKeepsSession() async {
            let (session, keychain) = makeStore(token: "stored-token")
            StubURLProtocol.setResponse(status: 200, json: Fixtures.user)
            await session.bootstrap()
            StubURLProtocol.setResponse(status: 403, json: #"{"error": "Incorrect password"}"#)

            do {
                try await session.deleteAccount(password: "wrong")
                Issue.record("expected deleteAccount to throw")
            } catch {
                // expected — state and token must be untouched
            }

            #expect(signedInUser(session.state) != nil)
            #expect(keychain.token == "stored-token")
        }

        @Test func signOutClearsTokenAndSignsOut() async {
            let (session, keychain) = makeStore(token: "stored-token")
            StubURLProtocol.setResponse(status: 200, json: "")

            await session.signOut()

            #expect(isSignedOut(session.state))
            #expect(keychain.token == nil)
        }

        // MARK: State helpers (SessionStore.State is intentionally not Equatable)

        private func isSignedOut(_ state: SessionStore.State) -> Bool {
            if case .signedOut = state { return true }
            return false
        }

        private func signedInUser(_ state: SessionStore.State) -> User? {
            if case .signedIn(let user) = state { return user }
            return nil
        }
    }
}
