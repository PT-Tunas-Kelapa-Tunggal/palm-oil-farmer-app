import SwiftUI

/// A large number that follows Dynamic Type, with an optional unit beside it.
struct ReviewAmountText: View {
    let value: String
    let unit: String?
    let unitFont: Font
    let unitIsSecondary: Bool

    @ScaledMetric private var size: CGFloat

    init(
        value: String,
        unit: String? = nil,
        size: CGFloat = 52,
        relativeTo textStyle: Font.TextStyle = .largeTitle,
        unitFont: Font = .headline,
        unitIsSecondary: Bool = false
    ) {
        self.value = value
        self.unit = unit
        self.unitFont = unitFont
        self.unitIsSecondary = unitIsSecondary
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(value)
                .font(.system(size: size, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let unit {
                Text(unit)
                    .font(unitFont)
                    .foregroundStyle(unitIsSecondary ? AnyShapeStyle(.secondary) : AnyShapeStyle(.foreground))
            }
        }
    }
}

#Preview("Ukuran angka", traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: 8) {
        ReviewAmountText(value: "30", unit: "kg")
        ReviewAmountText(value: "0,5", unit: "kg/pohon", size: 30, relativeTo: .title,
                         unitFont: .subheadline, unitIsSecondary: true)
        ReviewAmountText(value: "120m", size: 48)
    }
    .padding(16)
}
