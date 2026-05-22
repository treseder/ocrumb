import Foundation
import Observation

@Observable
final class RecipeListViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var recipes: [RecipeSummary] = []
    private(set) var loadState: LoadState = .idle

    private let api: APIClient

    init(api: APIClient = .shared) {
        self.api = api
    }

    func load() async {
        if recipes.isEmpty { loadState = .loading }
        do {
            recipes = try await api.fetchRecipes()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}
