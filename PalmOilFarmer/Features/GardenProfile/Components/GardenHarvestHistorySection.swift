import SwiftUI

struct GardenHarvestHistorySection: View {
    let harvest: HarvestRecord
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            GardenSectionHeader(title: "Riwayat Panen") { onEdit() }
            HarvestHistoryCard(record: harvest)
        }
        .padding(.horizontal, KropsTheme.Spacing.screen)
        .padding(.vertical, 8)
    }
}
