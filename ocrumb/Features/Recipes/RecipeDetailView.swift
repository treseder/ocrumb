import SwiftUI

struct RecipeDetailView: View {
    let initialTitle: String?

    @State private var model: RecipeDetailViewModel

    init(recipeID: Int, initialTitle: String?) {
        self.initialTitle = initialTitle
        _model = State(initialValue: RecipeDetailViewModel(recipeID: recipeID))
    }

    var body: some View {
        content
            .background(Theme.Colors.background)
            .navigationTitle(model.recipe?.title ?? initialTitle ?? "Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.load() }
            .refreshable { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        if let recipe = model.recipe {
            ScrollView {
                VStack(spacing: 0) {
                    hero(recipe)
                    VStack(spacing: Theme.Spacing.md) {
                        switch recipe.extractionStatus {
                        case .pending, .processing:
                            extractingSection
                        case .failed:
                            failedSection(recipe)
                        case .completed, .none:
                            loadedSection(recipe)
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
        } else {
            switch model.loadState {
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't load recipe", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await model.load() } }
                        .buttonStyle(.borderedProminent)
                }
            default:
                ProgressView().controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: Hero

    @ViewBuilder
    private func hero(_ recipe: Recipe) -> some View {
        if recipe.imageURL != nil {
            RecipeImage(url: recipe.imageURL)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.25)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                }
        }
    }

    // MARK: Status sections

    private var extractingSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .controlSize(.large)
            Text("Extracting recipe…")
                .font(Theme.Typography.rowTitle)
            Text("This usually takes a few seconds.")
                .font(.footnote)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
        .card()
    }

    @ViewBuilder
    private func failedSection(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("Extraction failed", systemImage: "exclamationmark.triangle.fill")
                .font(Theme.Typography.rowTitle)
                .foregroundStyle(Theme.Colors.danger)
            if let detail = recipe.extractionError, !detail.isEmpty {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            if let retryError = model.retryError {
                Text(retryError)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.danger)
            }
            Button {
                Task { await model.retry() }
            } label: {
                if model.isRetrying {
                    ProgressView().tint(.white)
                } else {
                    Text("Try Again")
                }
            }
            .buttonStyle(.primary)
            .disabled(model.isRetrying)
            .padding(.top, Theme.Spacing.xxs)
        }
        .card()
    }

    // MARK: Loaded content

    @ViewBuilder
    private func loadedSection(_ recipe: Recipe) -> some View {
        headerCard(recipe)
        if let meta = metaItems(recipe), !meta.isEmpty {
            metaCard(meta)
        }
        if !recipe.ingredients.isEmpty {
            ingredientsCard(recipe.ingredients)
        }
        if !recipe.instructions.isEmpty {
            instructionsCard(recipe.instructions)
        }
        if let source = recipe.source, !source.isEmpty {
            sourceCard(source)
        }
    }

    @ViewBuilder
    private func headerCard(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if let title = recipe.title, !title.isEmpty {
                Text(title)
                    .font(Theme.Typography.recipeTitle)
                    .foregroundStyle(Theme.Colors.primaryText)
            }
            if let description = recipe.description, !description.isEmpty {
                Text(description)
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            if !recipe.tags.isEmpty {
                FlowLayout {
                    ForEach(recipe.tags, id: \.self) { tag in
                        TagChip(text: tag)
                    }
                }
                .padding(.top, Theme.Spacing.xxs)
            }
        }
        .card()
    }

    private func metaItems(_ recipe: Recipe) -> [(String, String)]? {
        [
            recipe.servings.flatMap { $0.isEmpty ? nil : ("Servings", $0) },
            recipe.prepTimeMinutes.map { ("Prep", "\($0) min") },
            recipe.cookTimeMinutes.map { ("Cook", "\($0) min") },
            recipe.totalTimeMinutes.map { ("Total", "\($0) min") }
        ].compactMap { $0 }
    }

    private func metaCard(_ items: [(String, String)]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Divider().frame(height: 30)
                }
                MetaStat(label: item.0, value: item.1)
            }
        }
        .card()
    }

    private func ingredientsCard(_ ingredients: [Ingredient]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Ingredients", systemImage: "basket")
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                ForEach(ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(Theme.Colors.accent)
                            .frame(width: 6, height: 6)
                            .offset(y: -2)
                        Text(ingredient.displayString)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.primaryText)
                    }
                }
            }
        }
        .card()
    }

    private func instructionsCard(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Instructions", systemImage: "list.number")
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        stepBadge(index + 1)
                        Text(step)
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .card()
    }

    private func stepBadge(_ number: Int) -> some View {
        Text("\(number)")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Theme.Colors.accent)
            .frame(width: 28, height: 28)
            .background(Theme.Colors.accentSoft, in: Circle())
    }

    private func sourceCard(_ source: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            SectionHeader(title: "Source", systemImage: "link")
            if let url = URL(string: source), url.scheme?.hasPrefix("http") == true {
                Link(source, destination: url)
                    .font(.footnote)
                    .tint(Theme.Colors.accent)
            } else {
                Text(source)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
        }
        .card()
    }
}

private extension Ingredient {
    var displayString: String {
        [quantity, unit, item, prepNotes.map { "(\($0))" }]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: " ")
    }
}
