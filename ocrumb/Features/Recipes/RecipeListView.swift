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
    @State private var showingSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            content
                .background(Theme.Colors.background)
                .navigationTitle("Recipes")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline)
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
                .sheet(isPresented: $showingSettings) {
                    SettingsView(user: user)
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
                        .buttonStyle(.borderedProminent)
                }
            case .loaded:
                ContentUnavailableView {
                    Label("No recipes yet", systemImage: "book.pages")
                } description: {
                    Text("Tap + to extract a recipe from a photo.")
                } actions: {
                    Button {
                        showingAdd = true
                    } label: {
                        Text("Add a Recipe")
                            .padding(.horizontal, Theme.Spacing.xs)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(model.recipes) { recipe in
                        NavigationLink(value: RecipeRoute(id: recipe.id, title: recipe.title)) {
                            RecipeRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
            }
        }
    }
}

private struct RecipeRow: View {
    let recipe: RecipeSummary

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            RecipeImage(url: recipe.imageURL)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(recipe.title ?? "Untitled")
                    .font(Theme.Typography.rowTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
                    .lineLimit(2)

                subtitle

                if !recipe.tags.isEmpty {
                    Text(recipe.tags.prefix(3).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.tertiaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.Colors.tertiaryText)
        }
        .card()
    }

    @ViewBuilder
    private var subtitle: some View {
        switch recipe.extractionStatus {
        case .pending, .processing:
            Label("Extracting…", systemImage: "sparkles")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.accent)
        case .failed:
            Label("Extraction failed", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.danger)
        case .completed, .none:
            if let description = recipe.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .lineLimit(2)
            }
        }
    }
}
