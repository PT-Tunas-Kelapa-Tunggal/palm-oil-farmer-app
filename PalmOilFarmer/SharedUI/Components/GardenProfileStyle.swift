import SwiftUI

/// Legacy green-theme colours. Every use now has a `KropsTheme` replacement; this enum is removed once
/// the remaining features (Ajukan Peninjauan) and other branches have migrated.
enum GardenProfileStyle {
    @available(*, deprecated, renamed: "KropsTheme.surfaceBackground")
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .systemGroupedBackground
            : UIColor(red: 244 / 255, green: 245 / 255, blue: 246 / 255, alpha: 1)
    })
    @available(*, deprecated, renamed: "KropsTheme.surfaceBackground")
    static let formBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .systemGroupedBackground
            : UIColor(red: 244 / 255, green: 245 / 255, blue: 246 / 255, alpha: 1)
    })
    @available(*, deprecated, message: "Tema hijau lama. Tombol: KropsTheme.surfaceInverse. Ikon: accentHero. Teks oranye kecil: accentPrimary.")
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.2, green: 0.75, blue: 0.4, alpha: 1)
            : UIColor(red: 0.055, green: 0.51, blue: 0.23, alpha: 1)
    })
    @available(*, deprecated, renamed: "KropsTheme.surfaceCard")
    static let field = Color(uiColor: .secondarySystemGroupedBackground)
    @available(*, deprecated, renamed: "KropsTheme.surfaceCard")
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}
