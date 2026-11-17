import SwiftUI

/// Measurements shared by registration screens. Colours come from `KropsTheme`.
enum RegistrationStyle {
    static let cardRadius: CGFloat = 24
    static let panelTopRadius: CGFloat = 34
    static let panelBottomRadius: CGFloat = 54
    static let mapHeight: CGFloat = 220
    static let controlSize: CGFloat = 44

    // MARK: Legacy colours (removed once other branches have migrated)

    @available(*, deprecated, message: "Pakai KropsTheme.surfaceBackground (halaman) atau surfaceCardRaised (sheet).")
    static let background = Color(uiColor: .systemGroupedBackground)
    @available(*, deprecated, renamed: "KropsTheme.surfaceCard")
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    @available(*, deprecated, message: "Tombol utama: KropsTheme.surfaceInverse. Ikon/penanda peta: KropsTheme.accentHero.")
    static let actionTint = Color(red: 0.075, green: 0.49, blue: 0.235)
    @available(*, deprecated, renamed: "KropsTheme.labelInversePrimary")
    static let onAction = Color.white
}
