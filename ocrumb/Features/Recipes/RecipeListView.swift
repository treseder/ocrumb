import SwiftUI

struct RecipeRoute: Hashable {
    let id: Int
    let title: String?
}

struct RecipeListView: View {
    let user: User
    @Environment(SessionStore.self) private var session

    @State private var model = RecipeListViewModel()
    @State private var path: [RecipeRoute] = []
    @State private var showingAdd = false

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Recipes")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Sign Out") {
                            Task { await session.signOut() }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .task { await model.load() }
                .refreshable { await model.load() }
                .navigationDestination(for: RecipeRoute.self) { route in
                    RecipeDetailView(recipeID: route.id, initialTitle: route.title)
                }
                .sheet(isPresented: $showingAdd) {
                    AddRecipeView { recipe in
                        path.append(RecipeRoute(id: recipe.id, title: recipe.title))
                        Task { await model.load() }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.recipes.isEmpty {
            switch model.loadState {
            case .idle, .loading:
                ProgressView().controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't load recipes", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await model.load() } }
                }
            case .loaded:
                ContentUnavailableView {
                    Label("No recipes yet", systemImage: "book.pages")
                } description: {
                    Text("Tap + to extract a recipe from a photo.")
                }
            }
        } else {
            List(model.recipes) { recipe in
                NavigationLink(value: RecipeRoute(id: recipe.id, title: recipe.title)) {
                    RecipeRow(recipe: recipe)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct RecipeRow: View {
    let recipe: RecipeSummary

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(2)
                if let description = recipe.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if !recipe.tags.isEmpty {
                    Text(recipe.tags.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = recipe.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                default:
                    Color(.systemGray5)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 64, height: 64)
            .overlay {
                Image(systemName: "book.pages")
                    .foregroundStyle(.secondary)
            }
    }
}
