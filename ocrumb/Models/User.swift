import Foundation

nonisolated struct User: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let emailAddress: String
    let plan: String
    let extractionsCount: Int?
    let canExtract: Bool?
    let createdAt: Date?

    var isPro: Bool { plan.lowercased() != "free" }

    enum CodingKeys: String, CodingKey {
        case id
        case emailAddress = "email_address"
        case plan
        case extractionsCount = "extractions_count"
        case canExtract = "can_extract"
        case createdAt = "created_at"
    }
}

nonisolated struct AuthResponse: Codable, Sendable {
    let token: String
    let user: User
}
