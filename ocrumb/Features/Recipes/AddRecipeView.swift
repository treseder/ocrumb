import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    var onCreated: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isUploading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                preview

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(imageData == nil ? "Choose Photo" : "Change Photo",
                          systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(.bordered)

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    Task { await upload() }
                } label: {
                    if isUploading {
                        ProgressView()
                    } else {
                        Text("Extract Recipe").bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(imageData == nil || isUploading)
            }
            .padding()
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isUploading)
                }
            }
            .interactiveDismissDisabled(isUploading)
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadImage(from: newItem) }
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(maxHeight: 320)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Choose a recipe photo to extract")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
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

    private func upload() async {
        guard let imageData else { return }
        isUploading = true
        error = nil
        do {
            let recipe = try await APIClient.shared.createRecipe(
                imageData: imageData,
                filename: "recipe.jpg",
                mimeType: "image/jpeg"
            )
            onCreated(recipe)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isUploading = false
    }
}
