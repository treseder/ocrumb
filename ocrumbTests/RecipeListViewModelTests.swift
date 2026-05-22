import Foundation
import Testing
@testable import ocrumb

extension StubbedNetworkTests {
    @MainActor
    struct RecipeListViewModelTests {

        private func makeModel() -> RecipeListViewModel {
            RecipeListViewModel(api: APIClient(session: StubURLProtocol.makeSession()))
        }

        @Test func loadPopulatesRecipesAndMarksLoaded() async {
            StubURLProtocol.setResponse(status: 200, json: Fixtures.recipeList)
            let model = makeModel()

            await model.load()

            #expect(model.recipes.count == 1)
            #expect(model.recipes.first?.title == "Banana Bread")
            #expect(model.loadState == .loaded)
        }

        @Test func loadWithEmptyListStillMarksLoaded() async {
            StubURLProtocol.setResponse(status: 200, json: "[]")
            let model = makeModel()

            await model.load()

            #expect(model.recipes.isEmpty)
            #expect(model.loadState == .loaded)
        }

        @Test func loadFailureSurfacesFailedState() async {
            StubURLProtocol.setResponse(status: 500, json: "{}")
            let model = makeModel()

            await model.load()

            #expect(model.recipes.isEmpty)
            if case .failed = model.loadState {
                // expected
            } else {
                Issue.record("expected .failed, got \(model.loadState)")
            }
        }
    }
}
