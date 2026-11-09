import SwiftUI

/// Colors and measurements shared by registration screens.
enum RegistrationStyle {
    // Semantic grouped surfaces adapt to the system appearance and accessibility settings.
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let actionTint = Color(red: 0.075, green: 0.49, blue: 0.235)
    static let onAction = Color.white
    static let cardRadius: CGFloat = 24
    static let panelTopRadius: CGFloat = 34
    static let panelBottomRadius: CGFloat = 54
    static let mapHeight: CGFloat = 220
    static let controlSize: CGFloat = 44
}
