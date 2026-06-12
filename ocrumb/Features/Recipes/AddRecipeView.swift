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
                Picker("Source", selection: $model.source) {
                    ForEach(AddRecipeViewModel.Source.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)

                switch model.source {
                case .photo:
                    preview

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label(model.imageData == nil ? "Choose Photo" : "Change Photo",
                              systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(.secondary)
                case .link:
                    linkEntry
                }

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
                        if let recipe = await model.submit() {
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
                .disabled(!model.canSubmit)
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

    private var linkEntry: some View {
        VStack(spacing: Theme.Spacing.sm) {
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(Theme.Colors.fill)
                .frame(maxHeight: 200)
                .overlay {
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.Colors.accent)
                        Text("Paste a link to a recipe page")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }

            TextField("example.com/best-banana-bread", text: $model.urlString)
                .textContentType(.URL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .background(
                    Theme.Colors.fill,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                )

            Text("We'll pull the recipe straight from the page.")
                .font(.footnote)
                .foregroundStyle(Theme.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
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
