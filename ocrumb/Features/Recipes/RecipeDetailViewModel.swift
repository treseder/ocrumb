import Foundation
import Observation

@Observable
final class RecipeDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    let recipeID: Int
    private(set) var recipe: Recipe?
    private(set) var loadState: LoadState = .idle
    private(set) var isRetrying = false
    private(set) var retryError: String?

    private let api: APIClient
    private let pollInterval: Duration

    init(recipeID: Int, api: APIClient = .shared, pollInterval: Duration = .seconds(2)) {
        self.recipeID = recipeID
        self.api = api
        self.pollInterval = pollInterval
    }

    func load() async {
        if recipe == nil { loadState = .loading }
        do {
            recipe = try await api.fetchRecipe(id: recipeID)
            loadState = .loaded
            await pollWhileExtracting()
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func retry() async {
        isRetrying = true
        retryError = nil
        do {
            recipe = try await api.retryExtraction(recipeID: recipeID)
            await pollWhileExtracting()
        } catch {
            retryError = error.localizedDescription
        }
        isRetrying = false
    }

    private func pollWhileExtracting() async {
        while !Task.isCancelled, isExtracting(recipe?.extractionStatus) {
            do {
                try await Task.sleep(for: pollInterval)
            } catch {
                return
            }
            if Task.isCancelled { return }
            do {
                recipe = try await api.fetchRecipe(id: recipeID)
            } catch {
                // Transient errors during polling shouldn't tear down the view —
                // keep the last known state and try again next tick.
            }
        }
    }

    private func isExtracting(_ status: ExtractionStatus?) -> Bool {
        status == .pending || status == .processing
    }
}
