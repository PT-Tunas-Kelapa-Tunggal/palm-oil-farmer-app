import SwiftUI

/// Colors and measurements shared by registration screens.
enum RegistrationStyle {
    // Semantic grouped surfaces adapt to the system appearance and accessibility settings.
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let actionTint = Color(uiColor: .label)
    static let onAction = Color(uiColor: .systemBackground)
    static let cardRadius: CGFloat = 24
    static let panelTopRadius: CGFloat = 34
    static let panelBottomRadius: CGFloat = 54
    static let mapHeight: CGFloat = 201
    static let controlSize: CGFloat = 48
}
