import SwiftUI

struct AuthView: View {
    @Environment(SessionStore.self) private var session
    @State private var model = AuthViewModel()

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $model.mode) {
                        ForEach(AuthViewModel.Mode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("Email", text: $model.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $model.password)
                        .textContentType(model.mode == .register ? .newPassword : .password)
                    if model.mode == .register {
                        SecureField("Confirm password", text: $model.passwordConfirmation)
                            .textContentType(.newPassword)
                    }
                }

                if let errorMessage = model.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await model.submit(using: session) }
                    } label: {
                        HStack {
                            Spacer()
                            if model.isSubmitting {
                                ProgressView()
                            } else {
                                Text(model.submitTitle).bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(!model.canSubmit)
                }
            }
            .navigationTitle("ocrumb")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
