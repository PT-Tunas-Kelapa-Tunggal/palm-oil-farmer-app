import SwiftUI

/// Shared visual roles. Feature-specific map geometry stays in its feature.
enum KropsTheme {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .secondarySystemBackground
            : UIColor(white: 0.937, alpha: 1)
    })
    static let tertiaryFill = Color(uiColor: .tertiarySystemFill)
    static let secondaryFill = Color(uiColor: .secondarySystemFill)
    static let primaryText = Color.primary
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let titleText = Color.primary.opacity(0.7)
    static let buttonBackground = Color(white: 0.34)

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
