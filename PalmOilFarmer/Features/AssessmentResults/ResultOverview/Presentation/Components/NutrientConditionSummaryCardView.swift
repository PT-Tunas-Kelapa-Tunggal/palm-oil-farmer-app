import SwiftUI

/// Summary card displaying nutrient balance headline, narrative, and circular nutrient badges (N, P, K, Mg).
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Card / Kondisi Hara Copy"
public struct NutrientConditionSummaryCardView: View {
    public let title: String
    public let statusBadgeText: String
    public let summaryText: String
    public let nutrients: [NutrientStatusSummaryItem]
    public var onTap: (() -> Void)?

    private let orangeColor = Color(red: 1.0, green: 0.31, blue: 0.09) // #FF4F18
    private let statusRed = Color(red: 0.79, green: 0.22, blue: 0.05) // #C9390C
    private let darkPrimary = Color(red: 0.08, green: 0.08, blue: 0.09) // #141517
    private let graySecondary = Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.60) // #3C3C4399
    private let lightGray = Color(red: 0.95, green: 0.96, blue: 0.97) // #F2F4F7

    public init(
        title: String = "Kondisi Hara",
        statusBadgeText: String = "Belum Seimbang",
        summaryText: String = "Hasil dari praktik pemupukan Anda sebelumnya: dua hara kurang dan satu berlebih.",
        nutrients: [NutrientStatusSummaryItem],
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.statusBadgeText = statusBadgeText
        self.summaryText = summaryText
        self.nutrients = nutrients
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 14) {
                // Header Category Row
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(graySecondary)

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(graySecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(darkPrimary.opacity(0.55))
                }

                // Title Headline & Description
                VStack(alignment: .leading, spacing: 6) {
                    Text(statusBadgeText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(darkPrimary)

                    Text(summaryText)
                        .font(.system(size: 14))
                        .foregroundStyle(darkPrimary.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 4 Nutrient Badges in Horizontal Row
                HStack(spacing: 0) {
                    ForEach(nutrients) { item in
                        nutrientColumn(item)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nutrient Item

    private func nutrientColumn(_ item: NutrientStatusSummaryItem) -> some View {
        VStack(spacing: 8) {
            // 64x64 Circular Badge with bottom-right status mark
            ZStack(alignment: .bottomTrailing) {
                // Main circle
                Group {
                    if item.symbol == "P" {
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.90, green: 0.91, blue: 0.93), lineWidth: 1.5)
                            )
                    } else if item.symbol == "Mg" {
                        Circle()
                            .fill(lightGray)
                    } else {
                        Circle()
                            .fill(orangeColor)
                    }
                }
                .frame(width: 64, height: 64)

                // Symbol text inside main circle
                Text(item.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(badgeTextColor(for: item))
                    .frame(width: 64, height: 64)

                // 22x22 Status Mark Circle at bottom-right
                ZStack {
                    Circle()
                        .fill(statusMarkBackground(for: item.status))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )

                    statusMarkIcon(for: item.status)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .offset(x: 2, y: 2)
            }

            // Labels below badge
            VStack(spacing: 2) {
                Text(item.status.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(statusTextColor(for: item.status))

                Text(item.name)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(darkPrimary.opacity(0.72))
            }
        }
    }

    private func badgeTextColor(for item: NutrientStatusSummaryItem) -> Color {
        switch item.symbol {
        case "P":
            return statusRed
        case "Mg":
            return darkPrimary
        default:
            return Color.white
        }
    }

    private func statusMarkBackground(for status: NutrientConditionStatus) -> Color {
        switch status {
        case .cukup:
            return darkPrimary
        case .kurang, .berlebih:
            return orangeColor
        }
    }

    @ViewBuilder
    private func statusMarkIcon(for status: NutrientConditionStatus) -> some View {
        switch status {
        case .kurang:
            Image(systemName: "arrow.down")
        case .berlebih:
            Image(systemName: "arrow.up")
        case .cukup:
            Image(systemName: "checkmark")
        }
    }

    private func statusTextColor(for status: NutrientConditionStatus) -> Color {
        switch status {
        case .cukup:
            return darkPrimary
        case .kurang, .berlebih:
            return statusRed
        }
    }
}

#Preview {
    NutrientConditionSummaryCardView(
        nutrients: ResultOverviewItem.sample.nutrients
    )
    .padding()
    .background(Color(red: 0.95, green: 0.96, blue: 0.97))
}
