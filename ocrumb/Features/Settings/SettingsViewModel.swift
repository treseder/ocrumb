import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var deletePassword: String = ""
    var isDeleting: Bool = false
    var errorMessage: String?

    var canDelete: Bool {
        !isDeleting && !deletePassword.isEmpty
    }

    /// On success the session store signs out, which tears down the entire
    /// signed-in UI (including the settings sheet).
    func deleteAccount(using session: SessionStore) async {
        guard canDelete else { return }
        errorMessage = nil
        isDeleting = true
        defer {
            isDeleting = false
            deletePassword = ""
        }
        do {
            try await session.deleteAccount(password: deletePassword)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
