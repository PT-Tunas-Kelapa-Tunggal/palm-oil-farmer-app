import SwiftUI

/// Shared visual roles. Feature-specific map geometry stays in its feature.
///
/// Colour pairs were checked against WCAG 2.2: text and icons on their backgrounds are at least
/// 4.5:1, chart marks against their surface and against each other at least 3:1 (dark-mode chart
/// marks are about 2.8:1 against the card, so every chart also labels its marks and has a legend).
/// Status is never shown by colour alone: badges and chart states also carry an icon or text.
enum KropsTheme {
    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    // MARK: Brand

    /// Palm-leaf green for filled controls. White text on it: 6.4:1 light, 4.9:1 dark.
    static let primary = dynamic(light: 0x2E6B3F, dark: 0x3B7F4E)
    /// Green for text, links, and icons on the screen background: 5.9:1 light, 9.6:1 dark.
    static let primaryText = dynamic(light: 0x2E6B3F, dark: 0x8FD19E)
    /// Ripe fruit-bunch orange for small highlights: 4.9:1 light, 8.0:1 dark.
    static let accent = dynamic(light: 0xB5541A, dark: 0xF0A067)

    // MARK: Surfaces

    /// Surfaces are neutral grey so green stays reserved for primary actions and status.
    static let background = dynamic(light: 0xF2F2F2, dark: 0x1C1C1C)
    /// Grouped card and field background.
    static let cardFill = dynamic(light: 0xEAEAEA, dark: 0x2C2C2C)
    static let secondaryFill = Color(uiColor: .secondarySystemFill)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let titleText = Color.primary.opacity(0.7)
    static let buttonBackground = primary

    // MARK: Status (reserved; always paired with an icon or label)

    static let warningFill = dynamic(light: 0xFBEBD0, dark: 0x3A2A10)
    static let warningText = dynamic(light: 0x8A5300, dark: 0xF5C16C)

    // MARK: Charts

    enum Chart {
        /// Nutrient level now / after fertilizing.
        static let current = dynamic(light: 0x6E9F79, dark: 0x4E7A58)
        static let target = dynamic(light: 0x1F4D2C, dark: 0xB8E6C2)
        /// Rain below / at or above the heavy-rain threshold.
        static let lightRain = dynamic(light: 0x5E92C2, dark: 0x4A75A0)
        static let heavyRain = dynamic(light: 0x163F73, dark: 0xB5D6F5)
    }

    enum Typography {
        static let fieldLabel = Font.headline
        static let body = Font.body
        static let caption = Font.footnote
    }

    enum Radius {
        static let card: CGFloat = 24
        static let metric: CGFloat = 20
    }

    enum Spacing {
        static let compact: CGFloat = 8
        static let field: CGFloat = 12
        static let screen: CGFloat = 16
        static let content: CGFloat = 32
        static let section: CGFloat = 24
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
    }
}
