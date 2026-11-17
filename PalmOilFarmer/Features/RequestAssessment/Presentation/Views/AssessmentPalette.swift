import SwiftUI

@available(*, deprecated, message: "Tidak dipakai lagi. Pakai token KropsTheme; file ini dihapus saat pembersihan.")
struct AssessmentPalette {
    let isDark: Bool

    static let ink = Color(red: 20 / 255, green: 21 / 255, blue: 23 / 255)
    static let lightBackground = Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
    static let graphite = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)

    var background: Color { isDark ? Color(white: 15 / 255) : Self.lightBackground }
    var card: Color {
        isDark ? Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255) : .white
    }
    var primary: Color { isDark ? .primary : Self.ink }
    var secondary: Color {
        isDark ? Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255).opacity(191 / 255)
            : Self.ink.opacity(184 / 255)
    }
    var tertiary: Color {
        isDark ? Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255).opacity(140 / 255)
            : Self.ink.opacity(140 / 255)
    }
    var accent: Color {
        isDark ? Color(red: 210 / 255, green: 91 / 255, blue: 0)
            : Color(red: 1, green: 79 / 255, blue: 24 / 255)
    }
    var buttonTint: Color { isDark ? .white : Self.ink }
    var buttonLabel: Color { isDark ? .black : .white }
}
