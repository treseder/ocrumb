import Foundation
import Testing
@testable import ocrumb

extension StubbedNetworkTests {
    @MainActor
    struct AddRecipeViewModelTests {

        private func makeModel(imageData: Data?) -> AddRecipeViewModel {
            AddRecipeViewModel(
                api: APIClient(session: StubURLProtocol.makeSession()),
                imageData: imageData
            )
        }

        @Test func uploadReturnsCreatedRecipeOnSuccess() async {
            StubURLProtocol.setResponse(status: 200, json: Fixtures.recipe)
            let model = makeModel(imageData: Data("jpeg-bytes".utf8))

            let recipe = await model.upload()

            #expect(recipe?.id == 7)
            #expect(model.error == nil)
            #expect(model.isUploading == false)
        }

        @Test func uploadFailureSetsErrorAndReturnsNil() async {
            StubURLProtocol.setResponse(status: 422, json: Fixtures.validationErrors)
            let model = makeModel(imageData: Data("jpeg-bytes".utf8))

            let recipe = await model.upload()

            #expect(recipe == nil)
            #expect(model.error == "Email has already been taken, Password is too short")
            #expect(model.isUploading == false)
        }

        @Test func uploadWithoutImageReturnsNilWithoutError() async {
            let model = makeModel(imageData: nil)

            let recipe = await model.upload()

            #expect(recipe == nil)
            #expect(model.error == nil)
            #expect(model.canUpload == false)
        }

        @Test func extractFromLinkReturnsCreatedRecipeOnSuccess() async {
            StubURLProtocol.setResponse(status: 200, json: Fixtures.recipe)
            let model = makeModel(imageData: nil)
            model.source = .link
            model.urlString = "https://example.com/banana-bread"

            let recipe = await model.submit()

            #expect(recipe?.id == 7)
            #expect(model.error == nil)
            let request = StubURLProtocol.lastRequest
            #expect(request?.httpMethod == "POST")
            #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        }

        @Test func extractFromLinkFailureSetsError() async {
            StubURLProtocol.setResponse(status: 422, json: Fixtures.validationErrors)
            let model = makeModel(imageData: nil)
            model.source = .link
            model.urlString = "https://example.com/banana-bread"

            let recipe = await model.submit()

            #expect(recipe == nil)
            #expect(model.error != nil)
            #expect(model.isUploading == false)
        }

        @Test func normalizedURLStringAddsHTTPSAndTrims() {
            let model = makeModel(imageData: nil)

            model.urlString = "  example.com/banana-bread  "
            #expect(model.normalizedURLString == "https://example.com/banana-bread")

            model.urlString = "http://example.com/x"
            #expect(model.normalizedURLString == "http://example.com/x")
        }

        @Test func normalizedURLStringRejectsJunk() {
            let model = makeModel(imageData: nil)

            for junk in ["", "   ", "not a url", "https://", "banana"] {
                model.urlString = junk
                #expect(model.normalizedURLString == nil, "\(junk) should not normalize")
            }
        }

        @Test func canSubmitFollowsSelectedSource() {
            let model = makeModel(imageData: Data("jpeg-bytes".utf8))

            model.source = .photo
            #expect(model.canSubmit == true)

            model.source = .link
            #expect(model.canSubmit == false)

            model.urlString = "example.com/recipe"
            #expect(model.canSubmit == true)
        }
    }
}
