import SwiftUI

struct SettingsView: View {
    let user: User

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var model = SettingsViewModel()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Email", value: user.emailAddress)
                    LabeledContent("Plan", value: user.plan.capitalized)
                }

                Section {
                    Button("Sign Out") {
                        Task { await session.signOut() }
                    }
                }

                Section {
                    Button("Delete Account", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .disabled(model.isDeleting)
                } footer: {
                    Text("Permanently deletes your account and all of your recipes. This cannot be undone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
                SecureField("Password", text: $model.deletePassword)
                Button("Delete", role: .destructive) {
                    Task { await model.deleteAccount(using: session) }
                }
                Button("Cancel", role: .cancel) {
                    model.deletePassword = ""
                }
            } message: {
                Text("Enter your password to permanently delete your account and all recipes.")
            }
            .alert("Couldn't Delete Account", isPresented: deleteErrorShown) {
                Button("OK") { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private var deleteErrorShown: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }
}
