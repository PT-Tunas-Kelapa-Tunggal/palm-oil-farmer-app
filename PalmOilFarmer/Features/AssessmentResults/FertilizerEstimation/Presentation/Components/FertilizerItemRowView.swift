import SwiftUI

/// Table row representing a single fertilizer item with weight, bag count, pricing, and NPK customization trigger.
public struct FertilizerItemRowView: View {
    public let item: FertilizerItem
    public var onTapNPK: (() -> Void)?

    private let alertColor = Color(red: 1.0, green: 0.31, blue: 0.09) // #FF4F18

    public init(item: FertilizerItem, onTapNPK: (() -> Void)? = nil) {
        self.item = item
        self.onTapNPK = onTapNPK
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                // Column 1: Fertilizer Name & Price per bag
                VStack(alignment: .leading, spacing: 2) {
                    if item.isCustomizableNPK {
                        Button {
                            onTapNPK?()
                        } label: {
                            HStack(spacing: 4) {
                                Text(item.name)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))

                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(alertColor)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(uiColor: .systemGray6))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: NPKPillAnchorPreferenceKey.self,
                                    value: geo.frame(in: .named("FertilizerScreenSpace"))
                                )
                            }
                        )
                    } else {
                        Text(item.name)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
                    }

                    Text(item.formattedPricePerBag)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Column 2: Weight & Bag Count
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(item.weightKg) kg")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))

                    Text("\(item.bagCount) sak")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 70, alignment: .trailing)

                // Column 3: Total Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.formattedTotalPrice)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
                }
                .frame(width: 110, alignment: .trailing)
            }

            // Savings Hint Banner (if cheaper option exists)
            if let hint = item.savingsHint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    VStack {
        FertilizerItemRowView(
            item: FertilizerItem(
                id: "dolomit",
                name: "Dolomit",
                pricePerBag: 75000,
                weightKg: 400,
                bagCount: 8,
                totalPrice: 600000
            )
        )
        Divider()
        FertilizerItemRowView(
            item: FertilizerItem(
                id: "npk",
                name: "NPK 15-15-15",
                pricePerBag: 650000,
                weightKg: 350,
                bagCount: 7,
                totalPrice: 4550000,
                isCustomizableNPK: true,
                savingsHint: "Ada pilihan NPK yang Rp350.000 lebih hemat."
            )
        )
    }
    .padding()
}

// MARK: - Anchor Preference Key

public struct NPKPillAnchorPreferenceKey: PreferenceKey {
    public static var defaultValue: CGRect = .zero
    public static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

