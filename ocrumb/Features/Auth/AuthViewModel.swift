import Foundation
import Observation

@Observable
final class AuthViewModel {
    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case register = "Register"
        var id: String { rawValue }
    }

    var mode: Mode = .signIn
    var email: String = ""
    var password: String = ""
    var passwordConfirmation: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?

    var canSubmit: Bool {
        guard !isSubmitting, !email.isEmpty, !password.isEmpty else { return false }
        if mode == .register { return !passwordConfirmation.isEmpty }
        return true
    }

    var submitTitle: String {
        mode == .signIn ? "Sign In" : "Create Account"
    }

    func submit(using session: SessionStore) async {
        guard canSubmit else { return }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            switch mode {
            case .signIn:
                try await session.signIn(email: email, password: password)
            case .register:
                try await session.register(
                    email: email,
                    password: password,
                    confirm: passwordConfirmation
                )
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
