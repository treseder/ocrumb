import SwiftUI

struct RecipeDetailView: View {
    let recipeID: Int
    let initialTitle: String?

    @State private var recipe: Recipe?
    @State private var loadState: LoadState = .idle
    @State private var isRetrying = false
    @State private var retryError: String?

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var body: some View {
        content
            .navigationTitle(recipe?.title ?? initialTitle ?? "Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
            .refreshable { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let recipe {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let url = recipe.imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Color(.systemGray5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 240)
                        .clipped()
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        switch recipe.extractionStatus {
                        case .pending, .processing:
                            extractingSection
                        case .failed:
                            failedSection(recipe)
                        case .completed, .none:
                            loadedSection(recipe)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        } else {
            switch loadState {
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn't load recipe", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") { Task { await load() } }
                }
            default:
                ProgressView().controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var extractingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Extracting recipe…")
                .font(.headline)
            Text("This usually takes a few seconds.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    @ViewBuilder
    private func failedSection(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Extraction failed", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.red)
            if let detail = recipe.extractionError, !detail.isEmpty {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let retryError {
                Text(retryError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Button {
                Task { await retry() }
            } label: {
                if isRetrying {
                    ProgressView()
                } else {
                    Text("Try Again")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRetrying)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func loadedSection(_ recipe: Recipe) -> some View {
        header(recipe)
        meta(recipe)
        if !recipe.ingredients.isEmpty {
            ingredientsSection(recipe.ingredients)
        }
        if !recipe.instructions.isEmpty {
            instructionsSection(recipe.instructions)
        }
        if let source = recipe.source, !source.isEmpty {
            sourceSection(source)
        }
    }

    @ViewBuilder
    private func header(_ recipe: Recipe) -> some View {
        if let title = recipe.title, !title.isEmpty {
            Text(title)
                .font(.title2.bold())
        }
        if let description = recipe.description, !description.isEmpty {
            Text(description)
                .foregroundStyle(.secondary)
        }
        if !recipe.tags.isEmpty {
            HStack(spacing: 6) {
                ForEach(recipe.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6), in: Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private func meta(_ recipe: Recipe) -> some View {
        let items: [(String, String)] = [
            recipe.servings.flatMap { $0.isEmpty ? nil : ("Servings", $0) },
            recipe.prepTimeMinutes.map { ("Prep", "\($0) min") },
            recipe.cookTimeMinutes.map { ("Cook", "\($0) min") },
            recipe.totalTimeMinutes.map { ("Total", "\($0) min") }
        ].compactMap { $0 }

        if !items.isEmpty {
            HStack(spacing: 16) {
                ForEach(items, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.0)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.1)
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
    }

    private func ingredientsSection(_ ingredients: [Ingredient]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.headline)
            ForEach(ingredients) { ingredient in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•").foregroundStyle(.secondary)
                    Text(ingredient.displayString)
                }
            }
        }
    }

    private func instructionsSection(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(step)
                }
            }
        }
    }

    private func sourceSection(_ source: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Source")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let url = URL(string: source), url.scheme?.hasPrefix("http") == true {
                Link(source, destination: url)
                    .font(.footnote)
            } else {
                Text(source)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func load() async {
        if recipe == nil { loadState = .loading }
        do {
            recipe = try await APIClient.shared.fetchRecipe(id: recipeID)
            loadState = .loaded
            await pollWhileExtracting()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    private func pollWhileExtracting() async {
        while !Task.isCancelled, isExtracting(recipe?.extractionStatus) {
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            if Task.isCancelled { return }
            do {
                recipe = try await APIClient.shared.fetchRecipe(id: recipeID)
            } catch {
                // Transient errors during polling shouldn't tear down the view —
                // keep the last known state and try again next tick.
            }
        }
    }

    private func isExtracting(_ status: ExtractionStatus?) -> Bool {
        status == .pending || status == .processing
    }

    private func retry() async {
        isRetrying = true
        retryError = nil
        do {
            recipe = try await APIClient.shared.retryExtraction(recipeID: recipeID)
            await pollWhileExtracting()
        } catch {
            retryError = error.localizedDescription
        }
        isRetrying = false
    }
}

private extension Ingredient {
    var displayString: String {
        [quantity, unit, item, prepNotes.map { "(\($0))" }]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: " ")
    }
}
