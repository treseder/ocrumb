import Foundation
import Observation
import SwiftUI
import PhotosUI
import UIKit

@Observable
final class AddRecipeViewModel {
    private(set) var imageData: Data?
    private(set) var isUploading = false
    private(set) var error: String?

    private let api: APIClient

    init(api: APIClient = .shared, imageData: Data? = nil) {
        self.api = api
        self.imageData = imageData
    }

    var canUpload: Bool { imageData != nil && !isUploading }

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

    /// Uploads the selected image for extraction. Returns the created recipe,
    /// or `nil` if there's nothing to upload or the request failed (in which
    /// case `error` is set).
    func upload() async -> Recipe? {
        guard let imageData else { return nil }
        isUploading = true
        error = nil
        defer { isUploading = false }
        do {
            return try await api.createRecipe(
                imageData: imageData,
                filename: "recipe.jpg",
                mimeType: "image/jpeg"
            )
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
}
