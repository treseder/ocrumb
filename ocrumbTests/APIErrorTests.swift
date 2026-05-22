import Testing
@testable import ocrumb

/// Pure-logic tests for the user-facing strings `APIError` produces.
struct APIErrorTests {

    @Test func unauthorizedHasReauthMessage() {
        #expect(APIError.unauthorized.errorDescription == "Your session has expired. Please sign in again.")
    }

    @Test func serverErrorUsesServerMessageWhenPresent() {
        let error = APIError.server(status: 500, message: "Something broke")
        #expect(error.errorDescription == "Something broke")
    }

    @Test func serverErrorFallsBackWhenMessageMissing() {
        let error = APIError.server(status: 500, message: nil)
        #expect(error.errorDescription == "Server error.")
    }

    @Test func invalidURLMessage() {
        #expect(APIError.invalidURL.errorDescription == "Invalid URL.")
    }

    @Test func transportSurfacesUnderlyingDetail() {
        #expect(APIError.transport("The Internet connection appears to be offline.").errorDescription
                == "The Internet connection appears to be offline.")
    }
}
