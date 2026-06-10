import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    var onCreated: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var model = AddRecipeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                preview

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(model.imageData == nil ? "Choose Photo" : "Change Photo",
                          systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(.secondary)

                if let error = model.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    Task {
                        if let recipe = await model.upload() {
                            onCreated(recipe)
                            dismiss()
                        }
                    }
                } label: {
                    if model.isUploading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Extract Recipe")
                    }
                }
                .buttonStyle(.primary)
                .disabled(!model.canUpload)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.background)
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(model.isUploading)
                }
            }
            .interactiveDismissDisabled(model.isUploading)
            .onChange(of: selectedItem) { _, newItem in
                Task { await model.loadImage(from: newItem) }
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let imageData = model.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 360)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(Theme.Colors.fill)
                .frame(maxHeight: 360)
                .overlay {
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.Colors.accent)
                        Text("Choose a recipe photo to extract")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                        .strokeBorder(
                            Theme.Colors.separator.opacity(0.6),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                        )
                )
        }
    }
}
