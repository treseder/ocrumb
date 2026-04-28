import SwiftUI

struct RecipeListView: View {
    let user: User
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "book.pages")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                    .padding(.bottom, 8)
                Text("Signed in as \(user.emailAddress)")
                    .font(.headline)
                Text("Plan: \(user.plan.capitalized)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let count = user.extractionsCount {
                    Text("\(count) extractions used")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text("Recipe list coming soon.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 32)
                Spacer()
            }
            .padding()
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        Task { await session.signOut() }
                    }
                }
            }
        }
    }
}
