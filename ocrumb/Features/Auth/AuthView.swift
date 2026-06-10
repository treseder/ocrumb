import SwiftUI

struct AuthView: View {
    @Environment(SessionStore.self) private var session
    @State private var model = AuthViewModel()

    var body: some View {
        @Bindable var model = model

        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                brandHeader

                VStack(spacing: Theme.Spacing.md) {
                    Picker("Mode", selection: $model.mode) {
                        ForEach(AuthViewModel.Mode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: Theme.Spacing.sm) {
                        field {
                            TextField("Email", text: $model.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        field {
                            SecureField("Password", text: $model.password)
                                .textContentType(model.mode == .register ? .newPassword : .password)
                        }
                        if model.mode == .register {
                            field {
                                SecureField("Confirm password", text: $model.passwordConfirmation)
                                    .textContentType(.newPassword)
                            }
                        }
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await model.submit(using: session) }
                    } label: {
                        if model.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(model.submitTitle)
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(!model.canSubmit)
                    .padding(.top, Theme.Spacing.xxs)
                }
                .card(padding: Theme.Spacing.lg)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Colors.background)
    }

    private var brandHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "fork.knife")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(
                    Theme.Colors.accent,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                )
            Text("ocrumb")
                .font(Theme.Typography.screenTitle)
                .foregroundStyle(Theme.Colors.primaryText)
            Text("Snap a photo. Get the recipe.")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(.top, Theme.Spacing.xxl)
    }

    /// Wraps a text field in a recessed, rounded input surface.
    private func field<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .background(
                Theme.Colors.fill,
                in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
            )
    }
}
