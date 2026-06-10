import SwiftUI

/// Central design tokens for ocrumb. Keeping color, spacing, radius, and
/// typography in one place keeps every screen visually consistent and makes
/// global tweaks a one-line change.
enum Theme {

    // MARK: Color

    enum Colors {
        /// Brand green. Mirrors the `AccentColor` asset so SwiftUI's `.tint`
        /// and our explicit uses stay in sync.
        static let accent = Color.accentColor

        /// Soft tint of the brand color for fills behind accent content.
        static let accentSoft = Color.accentColor.opacity(0.12)

        /// Primary screen background.
        static let background = Color(.systemGroupedBackground)

        /// Raised surfaces (cards, rows) on top of `background`.
        static let surface = Color(.secondarySystemGroupedBackground)

        /// Recessed fills — chips, placeholders, thumbnails.
        static let fill = Color(.tertiarySystemFill)

        /// Hairline separators and card borders.
        static let separator = Color(.separator)

        static let primaryText = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)

        static let danger = Color(.systemRed)
    }

    // MARK: Spacing

    /// 4-pt spacing scale. Use these instead of magic numbers.
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: Typography

    /// Semantic type ramp built on SF Pro (the native iOS face). Centralizing
    /// these means weight/size decisions live in one spot.
    enum Typography {
        static let screenTitle = Font.largeTitle.bold()
        static let recipeTitle = Font.title2.weight(.bold)
        static let sectionHeader = Font.title3.weight(.semibold)
        static let rowTitle = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let metaValue = Font.subheadline.weight(.semibold)
        static let metaLabel = Font.caption.weight(.medium)
        static let chip = Font.caption.weight(.medium)
    }
}
