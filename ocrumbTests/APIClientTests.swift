import Foundation
import Testing
@testable import ocrumb

/// Parent suite for everything driven through `StubURLProtocol`. Marked
/// `.serialized` so the stub's global state is never shared across
/// concurrently-running tests (the trait applies to all nested suites too).
@Suite(.serialized)
struct StubbedNetworkTests {

    /// Drives `APIClient` over a stubbed `URLSession`, covering decoding,
    /// `CodingKeys`, custom date parsing, auth headers, and error mapping.
    struct APIClientTests {

        private func makeClient() -> APIClient {
            APIClient(session: StubURLProtocol.makeSession())
        }

        private static func iso(_ string: String) -> Date {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = f.date(from: string) { return date }
            f.formatOptions = [.withInternetDateTime]
            return f.date(from: string)!
        }

        @Test func fetchRecipeDecodesFieldsAndBothDateFormats() async throws {
            StubURLProtocol.setResponse(status: 200, json: Fixtures.recipe)
            let recipe = try await makeClient().fetchRecipe(id: 7)

            #expect(recipe.id == 7)
            #expect(recipe.title == "Banana Bread")
            #expect(recipe.totalTimeMinutes == 75)
            #expect(recipe.instructions.count == 3)
            #expect(recipe.tags == ["dessert", "baking"])
            #expect(recipe.extractionStatus == .completed)
            #expect(recipe.imageURL == URL(string: "https://example.com/img.jpg"))

            // CodingKeys + nested array decoding.
            #expect(recipe.ingredients.count == 2)
            #expect(recipe.ingredients.first?.item == "bananas")
            #expect(recipe.ingredients.first?.prepNotes == "ripe")
            #expect(recipe.ingredients.last?.unit == "cups")

            // Custom date strategy: fractional then plain fallback.
            #expect(recipe.createdAt == Self.iso("2026-05-20T12:00:00.123Z"))
            #expect(recipe.updatedAt == Self.iso("2026-05-20T12:30:00Z"))
        }

        @Test func fetchRecipesDecodesSummaryList() async throws {
            StubURLProtocol.setResponse(status: 200, json: Fixtures.recipeList)
            let recipes = try await makeClient().fetchRecipes()

            #expect(recipes.count == 1)
            #expect(recipes.first?.id == 7)
            #expect(recipes.first?.title == "Banana Bread")
            #expect(recipes.first?.extractionStatus == .completed)
        }

        @Test func signInDecodesTokenAndUser() async throws {
            StubURLProtocol.setResponse(status: 200, json: Fixtures.authResponse)
            let result = try await makeClient().signIn(email: "cook@example.com", password: "secret")

            #expect(result.token == "test-token-123")
            #expect(result.user.emailAddress == "cook@example.com")
            #expect(result.user.isPro == true)
        }

        @Test func unauthorizedStatusMapsToUnauthorizedError() async {
            StubURLProtocol.setResponse(status: 401, json: "")
            do {
                _ = try await makeClient().fetchAccount()
                Issue.record("expected fetchAccount to throw")
            } catch APIError.unauthorized {
                // expected
            } catch {
                Issue.record("expected .unauthorized, got \(error)")
            }
        }

        @Test func serverErrorJoinsErrorsArrayIntoMessage() async {
            StubURLProtocol.setResponse(status: 422, json: Fixtures.validationErrors)
            do {
                _ = try await makeClient().register(email: "a@b.com", password: "x", confirm: "x")
                Issue.record("expected register to throw")
            } catch APIError.server(let status, let message) {
                #expect(status == 422)
                #expect(message == "Email has already been taken, Password is too short")
            } catch {
                Issue.record("expected .server, got \(error)")
            }
        }

        @Test func deleteAccountSendsDeleteWithPasswordBody() async throws {
            let client = makeClient()
            await client.setToken("secret-token")
            StubURLProtocol.setResponse(status: 204, json: "")

            try await client.deleteAccount(password: "hunter2")

            let request = StubURLProtocol.lastRequest
            #expect(request?.httpMethod == "DELETE")
            #expect(request?.url?.path == "/api/v1/account")
            #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
            let body = StubURLProtocol.lastRequestBody.flatMap {
                try? JSONDecoder().decode([String: String].self, from: $0)
            }
            #expect(body == ["password": "hunter2"])
        }

        @Test func deleteAccountWrongPasswordMapsToServerError() async {
            StubURLProtocol.setResponse(status: 403, json: #"{"error": "Incorrect password"}"#)
            do {
                try await makeClient().deleteAccount(password: "wrong")
                Issue.record("expected deleteAccount to throw")
            } catch APIError.server(let status, let message) {
                #expect(status == 403)
                #expect(message == "Incorrect password")
            } catch {
                Issue.record("expected .server, got \(error)")
            }
        }

        @Test func authorizedRequestSendsBearerHeader() async throws {
            let client = makeClient()
            await client.setToken("secret-token")
            StubURLProtocol.setResponse(status: 200, json: Fixtures.user)

            _ = try await client.fetchAccount()

            let header = StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization")
            #expect(header == "Bearer secret-token")
        }

        @Test func unauthenticatedEndpointOmitsBearerHeaderEvenWithToken() async throws {
            let client = makeClient()
            await client.setToken("secret-token")
            StubURLProtocol.setResponse(status: 200, json: Fixtures.authResponse)

            // signIn is sent with authorized: false.
            _ = try await client.signIn(email: "cook@example.com", password: "secret")

            let header = StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization")
            #expect(header == nil)
        }
    }
}
