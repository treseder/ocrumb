import Foundation
import Observation

@Observable
final class SessionStore {
    enum State {
        case loading
        case signedOut
        case signedIn(User)
    }

    var state: State = .loading

    private let api: APIClient
    private let keychain: any TokenStore

    init(api: APIClient = .shared, keychain: any TokenStore = KeychainStore.shared) {
        self.api = api
        self.keychain = keychain
    }

    func bootstrap() async {
        guard let token = keychain.token else {
            state = .signedOut
            return
        }
        await api.setToken(token)
        do {
            let user = try await api.fetchAccount()
            state = .signedIn(user)
        } catch APIError.unauthorized {
            keychain.token = nil
            await api.setToken(nil)
            state = .signedOut
        } catch {
            // Offline or transient failure — fall through to signed out
            // so the user can retry. Token is preserved for the next launch.
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await api.signIn(email: email, password: password)
        await applySuccess(result)
    }

    func register(email: String, password: String, confirm: String) async throws {
        let result = try await api.register(email: email, password: password, confirm: confirm)
        await applySuccess(result)
    }

    func signOut() async {
        try? await api.signOut()
        keychain.token = nil
        await api.setToken(nil)
        state = .signedOut
    }

    private func applySuccess(_ result: AuthResponse) async {
        keychain.token = result.token
        await api.setToken(result.token)
        state = .signedIn(result.user)
    }
}
