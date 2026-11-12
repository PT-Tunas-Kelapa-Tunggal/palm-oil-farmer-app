import SwiftUI

/// Bottom sheet displaying the condition legend categories and tree counts using Liquid Glass.
/// Sliced from Sketch: "Hasil Peninjauan / Peta Kondisi Kebun / Legend" -> "Template / Sheet / Small Detent", "Arsip / Panel (manual)"
public struct FarmGreenIndexLegendSheetView: View {
    public let categories: [TreeConditionSummaryItem]
    public var onSelectCategory: ((TreeConditionCategory) -> Void)?
    public var onCollapse: (() -> Void)?

    private let darkPrimary = Color(red: 0.08, green: 0.08, blue: 0.09) // #141517

    public init(
        categories: [TreeConditionSummaryItem],
        onSelectCategory: ((TreeConditionCategory) -> Void)? = nil,
        onCollapse: (() -> Void)? = nil
    ) {
        self.categories = categories
        self.onSelectCategory = onSelectCategory
        self.onCollapse = onCollapse
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Grabber handle
            HStack {
                Spacer()
                Button(action: { onCollapse?() }) {
                    Capsule()
                        .fill(darkPrimary.opacity(0.20))
                        .frame(width: 44, height: 4)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tutup Legenda")
                Spacer()
            }

            // Header Title & Subtitle (Left-aligned matching Sketch)
            VStack(alignment: .leading, spacing: 3) {
                Text("Kondisi Pohon")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(darkPrimary)

                Text("Warna pada peta menunjukkan kesehatan setiap pohon.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(darkPrimary.opacity(0.72))
            }
            .padding(.horizontal, 4)

            // 4 Category Rows (Normal, Terindikasi, Defisiensi, Tidak Wajar)
            VStack(spacing: 8) {
                ForEach(categories) { item in
                    Button(action: { onSelectCategory?(item.category) }) {
                        categoryRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 36)
        .glassEffect(
            .regular,
            in: UnevenRoundedRectangle(
                topLeadingRadius: 32,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 32,
                style: .continuous
            )
        )
    }

    private func categoryRow(_ item: TreeConditionSummaryItem) -> some View {
        let dotColor = Color(hex: item.category.colorHex)

        return HStack(spacing: 12) {
            // Condition color dot
            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)

            // Titles (Left-aligned)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.category.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(darkPrimary)

                Text(item.category.shortLegend)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(darkPrimary.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer()

            // Tree count (Right-aligned bold text)
            Text("\(item.treeCount)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(darkPrimary)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(darkPrimary.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            FarmGreenIndexLegendSheetView(
                categories: FarmGreenIndexItem.sample.categories
            )
        }
    }
}
