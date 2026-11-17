import SwiftUI

/// Warning callout row highlighting agronomic impacts of nutrient imbalance.
public struct NutrientWarningRow: View {
    public let message: String


    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(KropsTheme.accentHero)
                .frame(width: 20, height: 20, alignment: .top)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(KropsTheme.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NutrientWarningRow(
        message: "Kekurangan nitrogen membuat pelepah menguning dan jumlah pelepah baru berkurang."
    )
    .padding()
}

