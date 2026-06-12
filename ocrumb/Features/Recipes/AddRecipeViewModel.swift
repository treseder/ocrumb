import Foundation
import Observation
import SwiftUI
import PhotosUI
import UIKit

@Observable
final class AddRecipeViewModel {
    enum Source: String, CaseIterable, Identifiable {
        case photo = "Photo"
        case link = "Link"
        var id: String { rawValue }
    }

    var source: Source = .photo
    var urlString = ""
    private(set) var imageData: Data?
    private(set) var isUploading = false
    private(set) var error: String?

    private let api: APIClient

    init(api: APIClient = .shared, imageData: Data? = nil) {
        self.api = api
        self.imageData = imageData
    }

    var canUpload: Bool { imageData != nil && !isUploading }

    /// The pasted link, trimmed and defaulted to https:// when the user left
    /// the scheme off. `nil` when it can't become a usable URL.
    var normalizedURLString: String? {
        var trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lowered = trimmed.lowercased()
        if !lowered.hasPrefix("http://") && !lowered.hasPrefix("https://") {
            trimmed = "https://" + trimmed
        }
        guard !trimmed.contains(" "),
              let url = URL(string: trimmed),
              let host = url.host, host.contains(".") else { return nil }
        return trimmed
    }

    var canSubmit: Bool {
        guard !isUploading else { return false }
        switch source {
        case .photo: return imageData != nil
        case .link: return normalizedURLString != nil
        }
    }

    func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let jpeg = uiImage.jpegData(compressionQuality: 0.85) else {
                error = "Couldn't read that photo."
                return
            }
            imageData = jpeg
            error = nil
        } catch {
            self.error = "Couldn't load photo: \(error.localizedDescription)"
        }
    }

    /// Creates the recipe from whichever source is selected. Returns the
    /// created recipe, or `nil` if there's nothing to submit or the request
    /// failed (in which case `error` is set).
    func submit() async -> Recipe? {
        switch source {
        case .photo: return await upload()
        case .link: return await extractFromLink()
        }
    }

    func upload() async -> Recipe? {
        guard let imageData else { return nil }
        return await create {
            try await self.api.createRecipe(
                imageData: imageData,
                filename: "recipe.jpg",
                mimeType: "image/jpeg"
            )
        }
    }

    func extractFromLink() async -> Recipe? {
        guard let sourceURL = normalizedURLString else { return nil }
        return await create {
            try await self.api.createRecipe(sourceURL: sourceURL)
        }
    }

    private func create(_ request: () async throws -> Recipe) async -> Recipe? {
        isUploading = true
        error = nil
        defer { isUploading = false }
        do {
            return try await request()
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
}
