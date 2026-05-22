import Testing
@testable import ocrumb

/// Pure-logic tests for `AuthViewModel`'s form gating and titles.
/// MainActor because `AuthViewModel` is MainActor-isolated (project default).
@MainActor
struct AuthViewModelTests {

    @Test func signInRequiresEmailAndPassword() {
        let model = AuthViewModel()
        model.mode = .signIn
        #expect(model.canSubmit == false)

        model.email = "cook@example.com"
        #expect(model.canSubmit == false)

        model.password = "secret"
        #expect(model.canSubmit == true)
    }

    @Test func registerAlsoRequiresConfirmation() {
        let model = AuthViewModel()
        model.mode = .register
        model.email = "cook@example.com"
        model.password = "secret"
        #expect(model.canSubmit == false)

        model.passwordConfirmation = "secret"
        #expect(model.canSubmit == true)
    }

    @Test func submittingDisablesFurtherSubmits() {
        let model = AuthViewModel()
        model.email = "cook@example.com"
        model.password = "secret"
        model.isSubmitting = true
        #expect(model.canSubmit == false)
    }

    @Test func submitTitleFollowsMode() {
        let model = AuthViewModel()
        model.mode = .signIn
        #expect(model.submitTitle == "Sign In")

        model.mode = .register
        #expect(model.submitTitle == "Create Account")
    }
}
