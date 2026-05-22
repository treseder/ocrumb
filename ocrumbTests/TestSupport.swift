import Foundation
@testable import ocrumb

/// In-memory `TokenStore` so `SessionStore` tests never touch the Keychain.
final class InMemoryTokenStore: TokenStore {
    var token: String?
    init(token: String? = nil) { self.token = token }
}

/// JSON the real API returns, used to drive decoding through `APIClient`.
enum Fixtures {
    /// `created_at` uses plain ISO8601 (no fractional seconds).
    static let user = """
    {
      "id": 42,
      "email_address": "cook@example.com",
      "plan": "free",
      "extractions_count": 3,
      "can_extract": true,
      "created_at": "2026-05-20T12:00:00Z"
    }
    """

    static let authResponse = """
    {
      "token": "test-token-123",
      "user": {
        "id": 42,
        "email_address": "cook@example.com",
        "plan": "pro",
        "extractions_count": 3,
        "can_extract": true,
        "created_at": "2026-05-20T12:00:00Z"
      }
    }
    """

    /// `created_at` has fractional seconds, `updated_at` does not — exercises
    /// both branches of `APIClient`'s custom date decoding in one decode.
    static let recipe = """
    {
      "id": 7,
      "title": "Banana Bread",
      "description": "Moist and easy",
      "servings": "8 slices",
      "source": "https://example.com/banana-bread",
      "prep_time_minutes": 15,
      "cook_time_minutes": 60,
      "total_time_minutes": 75,
      "instructions": ["Mash bananas", "Mix dry and wet", "Bake at 350F"],
      "tags": ["dessert", "baking"],
      "edited": false,
      "extraction_status": "completed",
      "extraction_error": null,
      "image_url": "https://example.com/img.jpg",
      "ingredients": [
        {"id": 1, "quantity": "3", "unit": null, "item": "bananas", "prep_notes": "ripe", "position": 0},
        {"id": 2, "quantity": "2", "unit": "cups", "item": "flour", "prep_notes": null, "position": 1}
      ],
      "created_at": "2026-05-20T12:00:00.123Z",
      "updated_at": "2026-05-20T12:30:00Z"
    }
    """

    static let recipeList = """
    [
      {
        "id": 7,
        "title": "Banana Bread",
        "description": "Moist and easy",
        "tags": ["dessert"],
        "extraction_status": "completed",
        "image_url": "https://example.com/img.jpg",
        "created_at": "2026-05-20T12:00:00Z"
      }
    ]
    """

    static let validationErrors = """
    {"errors": ["Email has already been taken", "Password is too short"]}
    """

    /// Same recipe (id 7) mid-extraction — drives the polling loop.
    static let recipeProcessing = """
    {
      "id": 7,
      "title": null,
      "description": null,
      "servings": null,
      "source": null,
      "prep_time_minutes": null,
      "cook_time_minutes": null,
      "total_time_minutes": null,
      "instructions": [],
      "tags": [],
      "edited": false,
      "extraction_status": "processing",
      "extraction_error": null,
      "image_url": "https://example.com/img.jpg",
      "ingredients": [],
      "created_at": "2026-05-20T12:00:00Z",
      "updated_at": "2026-05-20T12:00:00Z"
    }
    """

    static let recipeFailed = """
    {
      "id": 8,
      "title": null,
      "description": null,
      "servings": null,
      "source": null,
      "prep_time_minutes": null,
      "cook_time_minutes": null,
      "total_time_minutes": null,
      "instructions": [],
      "tags": [],
      "edited": false,
      "extraction_status": "failed",
      "extraction_error": "Could not read the recipe from the photo.",
      "image_url": "https://example.com/img.jpg",
      "ingredients": [],
      "created_at": "2026-05-20T12:00:00Z",
      "updated_at": "2026-05-20T12:00:00Z"
    }
    """
}
