import SwiftUI

enum GardenProfileStyle {
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .systemGroupedBackground
            : UIColor(red: 244 / 255, green: 245 / 255, blue: 246 / 255, alpha: 1)
    })
    static let formBackground = background
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.2, green: 0.75, blue: 0.4, alpha: 1)
            : UIColor(red: 0.055, green: 0.51, blue: 0.23, alpha: 1)
    })
    static let field = Color(uiColor: .secondarySystemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}

