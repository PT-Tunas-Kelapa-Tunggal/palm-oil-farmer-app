import SwiftUI

/// Reusable 44x44 circular element badge showing the chemical symbol (e.g., N, P, K, Mg).
public struct NutrientBadgeView: View {
    public let symbol: String
    public var size: CGFloat = 44

    public init(symbol: String, size: CGFloat = 44) {
        self.symbol = symbol
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.08, green: 0.08, blue: 0.09))
                .frame(width: size, height: size)

            Text(symbol)
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
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

