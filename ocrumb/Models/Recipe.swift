import Foundation

nonisolated enum ExtractionStatus: String, Codable, Sendable {
    case pending
    case processing
    case completed
    case failed
}

nonisolated struct RecipeSummary: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let title: String?
    let description: String?
    let tags: [String]
    let extractionStatus: ExtractionStatus?
    let imageURL: URL?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case tags
        case extractionStatus = "extraction_status"
        case imageURL = "image_url"
        case createdAt = "created_at"
    }
}

nonisolated struct Recipe: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let title: String?
    let description: String?
    let servings: String?
    let source: String?
    let sourceUrl: String?
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let totalTimeMinutes: Int?
    let instructions: [String]
    let tags: [String]
    let edited: Bool
    let extractionStatus: ExtractionStatus?
    let extractionError: String?
    let imageURL: URL?
    let ingredients: [Ingredient]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case servings
        case source
        case sourceUrl = "source_url"
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case totalTimeMinutes = "total_time_minutes"
        case instructions
        case tags
        case edited
        case extractionStatus = "extraction_status"
        case extractionError = "extraction_error"
        case imageURL = "image_url"
        case ingredients
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

nonisolated struct Ingredient: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let quantity: String?
    let unit: String?
    let item: String?
    let prepNotes: String?
    let position: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case quantity
        case unit
        case item
        case prepNotes = "prep_notes"
        case position
    }
}
