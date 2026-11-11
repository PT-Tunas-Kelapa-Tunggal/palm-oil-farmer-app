import SwiftUI

/// Warning callout row highlighting agronomic impacts of nutrient imbalance.
public struct NutrientWarningRow: View {
    public let message: String

    private let alertColor = Color(red: 1.0, green: 0.31, blue: 0.09) // #FF4F18

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(alertColor)
                .frame(width: 20, height: 20, alignment: .top)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
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

