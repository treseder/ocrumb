import Foundation
import Testing
@testable import ocrumb

extension StubbedNetworkTests {
    @MainActor
    struct RecipeDetailViewModelTests {

        /// Tiny poll interval so the extraction-polling loop runs instantly.
        private func makeModel(recipeID: Int = 7) -> RecipeDetailViewModel {
            RecipeDetailViewModel(
                recipeID: recipeID,
                api: APIClient(session: StubURLProtocol.makeSession()),
                pollInterval: .milliseconds(1)
            )
        }

        @Test func loadCompletedRecipeDoesNotPoll() async {
            StubURLProtocol.setResponse(status: 200, json: Fixtures.recipe)
            let model = makeModel()

            await model.load()

            #expect(model.loadState == .loaded)
            #expect(model.recipe?.title == "Banana Bread")
            #expect(model.recipe?.extractionStatus == .completed)
        }

        @Test func loadFailedRecipeKeepsFailedStatusForRetryUI() async {
            StubURLProtocol.setResponse(status: 200, json: Fixtures.recipeFailed)
            let model = makeModel(recipeID: 8)

            await model.load()

            #expect(model.loadState == .loaded)
            #expect(model.recipe?.extractionStatus == .failed)
            #expect(model.recipe?.extractionError == "Could not read the recipe from the photo.")
        }

        @Test func loadFetchFailureSurfacesFailedState() async {
            StubURLProtocol.setResponse(status: 500, json: "{}")
            let model = makeModel()

            await model.load()

            #expect(model.recipe == nil)
            if case .failed = model.loadState {
                // expected
            } else {
                Issue.record("expected .failed, got \(model.loadState)")
            }
        }

        @Test func loadPollsUntilExtractionCompletes() async {
            // First fetch is still processing, the next is completed.
            StubURLProtocol.setResponses([
                (200, Fixtures.recipeProcessing),
                (200, Fixtures.recipe)
            ])
            let model = makeModel()

            await model.load()

            #expect(model.recipe?.extractionStatus == .completed)
            #expect(model.recipe?.title == "Banana Bread")
        }

        @Test func retrySucceedsAndPollsToCompletion() async {
            StubURLProtocol.setResponses([
                (200, Fixtures.recipeProcessing),
                (200, Fixtures.recipe)
            ])
            let model = makeModel()

            await model.retry()

            #expect(model.isRetrying == false)
            #expect(model.retryError == nil)
            #expect(model.recipe?.extractionStatus == .completed)
        }

        @Test func retryFailureSurfacesRetryError() async {
            StubURLProtocol.setResponse(status: 500, json: "{}")
            let model = makeModel()

            await model.retry()

            #expect(model.isRetrying == false)
            #expect(model.retryError != nil)
        }
    }
}
