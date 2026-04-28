import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.state {
            case .loading:
                ProgressView()
                    .controlSize(.large)
                    .task { await session.bootstrap() }
            case .signedOut:
                AuthView()
            case .signedIn(let user):
                RecipeListView(user: user)
            }
        }
    }
}
