import SwiftUI

/// Side-by-side metric comparison displaying current fertilization practice vs required threshold.
public struct NutrientComparisonView: View {
    public let comparison: NutrientComparison

    public init(comparison: NutrientComparison) {
        self.comparison = comparison
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: Current Practice (Praktik saat ini)
            VStack(alignment: .leading, spacing: 4) {
                Text(comparison.currentPracticeLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(comparison.currentPracticeValue)")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.secondary)

                    Text(comparison.unit)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: Recommended Need (Kebutuhan)
            VStack(alignment: .leading, spacing: 4) {
                Text(comparison.requiredLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(comparison.requiredValue)")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))

                    Text(comparison.unit)
                        .font(.callout)
                        .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NutrientComparisonView(
        comparison: NutrientComparison(
            currentPracticeValue: 173,
            currentPracticeLabel: "Praktik saat ini",
            requiredValue: 190,
            requiredLabel: "Kebutuhan",
            unit: "kg"
        )
    )
    .padding()
}

