import SwiftUI

struct GardenFertilizerHistorySection: View {
    let fertilizers: [FertilizerRecord]
    let hasHarvest: Bool
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            GardenSectionHeader(title: "Riwayat pupuk") { onEdit() }
            VStack(spacing: 8) {
                ForEach(fertilizers) { record in
                    FertilizerHistoryCard(record: record)
                }
            }
        }
        .padding(.horizontal, KropsTheme.Spacing.screen)
        .padding(.top, 8)
        .padding(.bottom, !hasHarvest ? 24 : 8)
    }
}
