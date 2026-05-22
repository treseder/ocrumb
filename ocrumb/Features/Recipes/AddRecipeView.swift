import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    var onCreated: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var model = AddRecipeViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                preview

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(model.imageData == nil ? "Choose Photo" : "Change Photo",
                          systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(.bordered)

                if let error = model.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
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
                        ProgressView()
                    } else {
                        Text("Extract Recipe").bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(!model.canUpload)
            }
            .padding()
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
}
