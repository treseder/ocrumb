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
    }
}
