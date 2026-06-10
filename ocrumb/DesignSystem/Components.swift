import SwiftUI

// MARK: - Card

/// Wraps content in a raised, rounded surface with a hairline border.
private struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Theme.Colors.surface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .strokeBorder(Theme.Colors.separator.opacity(0.5), lineWidth: 0.5)
            )
    }
}

extension View {
    /// Presents the view as a card surface. Default padding suits most sections.
    func card(padding: CGFloat = Theme.Spacing.md) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Section header

/// A consistent section title with an optional leading SF Symbol.
struct SectionHeader: View {
    let title: String
    var systemImage: String?

    var body: some View {
        Label {
            Text(title)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
        .labelStyle(.titleAndIcon)
        .font(Theme.Typography.sectionHeader)
        .foregroundStyle(Theme.Colors.primaryText)
    }
}

// MARK: - Tag chip

/// A pill-shaped tag rendered in the brand tint.
struct TagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Typography.chip)
            .foregroundStyle(Theme.Colors.accent)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xxs + 2)
            .background(Theme.Colors.accentSoft, in: Capsule())
    }
}

// MARK: - Meta stat

/// A stacked value/label pair used for servings and timings.
struct MetaStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.Typography.metaValue)
                .foregroundStyle(Theme.Colors.primaryText)
            Text(label.uppercased())
                .font(Theme.Typography.metaLabel)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recipe image

/// Shared async image with a branded placeholder. Fills its frame; callers
/// apply their own `.frame` and clip shape.
struct RecipeImage: View {
    let url: URL?

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                default:
                    Theme.Colors.fill.overlay { ProgressView() }
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Theme.Colors.fill.overlay {
            Image(systemName: "fork.knife")
                .font(.title3)
                .foregroundStyle(Theme.Colors.tertiaryText)
        }
    }
}

// MARK: - Flow layout

/// Wraps subviews onto multiple lines, like flowing text. Used for tag chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = Theme.Spacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(maxWidth, widest), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Button styles

/// Filled, full-width primary action in the brand tint.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonLabel(configuration: configuration)
    }

    private struct PrimaryButtonLabel: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm + 2)
                .background(
                    Theme.Colors.accent,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                )
                .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

/// Tinted, full-width secondary action on a soft accent fill.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.Colors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm + 2)
            .background(
                Theme.Colors.accentSoft,
                in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
