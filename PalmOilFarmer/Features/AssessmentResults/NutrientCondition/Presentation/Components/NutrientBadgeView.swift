import SwiftUI

/// Reusable 44x44 circular element badge showing the chemical symbol (e.g., N, P, K, Mg).
public struct NutrientBadgeView: View {
    public let symbol: String
    public var size: CGFloat = 44
    /// Scales the badge with Dynamic Type so the symbol grows with the user's text size.
    @ScaledMetric(relativeTo: .title3) private var scale: CGFloat = 1

    public init(symbol: String, size: CGFloat = 44) {
        self.symbol = symbol
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(KropsTheme.surfaceInverse)
                .frame(width: size * scale, height: size * scale)

            Text(symbol)
                .font(.system(size: size * 0.45 * scale, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        NutrientBadgeView(symbol: "N")
        NutrientBadgeView(symbol: "P")
        NutrientBadgeView(symbol: "K")
        NutrientBadgeView(symbol: "Mg")
    }
    .padding()
}

