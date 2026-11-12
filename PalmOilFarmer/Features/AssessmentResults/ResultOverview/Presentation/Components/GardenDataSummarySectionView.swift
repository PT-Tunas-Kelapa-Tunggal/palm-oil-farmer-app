import SwiftUI

/// Section displaying the locked garden data rows (Identitas Kebun, Riwayat Panen dan Pemupukan, Pengajuan Peninjauan).
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Section / Data Kebun"
public struct GardenDataSummarySectionView: View {
    public let title: String
    public let message: String
    public let rows: [GardenDataSummaryRowItem]
    public var onTapRow: ((GardenDataSummaryRowItem) -> Void)?

    private let darkPrimary = Color(red: 0.08, green: 0.08, blue: 0.09) // #141517
    private let lightGrayCircle = Color(red: 0.95, green: 0.96, blue: 0.97) // #F2F4F7

    public init(
        title: String = "Data Kebun",
        message: String = "Data yang Anda isi dan menjadi dasar hasil peninjauan.",
        rows: [GardenDataSummaryRowItem],
        onTapRow: ((GardenDataSummaryRowItem) -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.rows = rows
        self.onTapRow = onTapRow
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(darkPrimary)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(darkPrimary.opacity(0.65))
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)

            // Rows list (76 pt tall each)
            VStack(spacing: 8) {
                ForEach(rows) { item in
                    Button(action: { onTapRow?(item) }) {
                        HStack(spacing: 14) {
                            // 40x40 circle background for icon
                            Image(systemName: item.iconSystemName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(darkPrimary.opacity(0.65))
                                .frame(width: 40, height: 40)
                                .background(lightGrayCircle)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(darkPrimary)

                                Text(item.subtitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(darkPrimary.opacity(0.65))
                                    .lineLimit(1)
                            }

                            Spacer()

                            if item.isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(darkPrimary.opacity(0.35))
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(darkPrimary.opacity(0.35))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    GardenDataSummarySectionView(
        rows: ResultOverviewItem.sample.gardenDataRows
    )
    .padding()
    .background(Color(red: 0.95, green: 0.96, blue: 0.97))
}
