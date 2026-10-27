import SwiftUI

#if DEBUG
#Preview("Pemupukan · Filled", traits: .fixedLayout(width: 402, height: 918)) {
    FertilizerHistoryScreen(
        records: [FertilizerRecord(name: "Dolomit Super", bagWeightKg: 50, bagCount: 6, doseKgPerTree: 1.5)],
        includesEmptyDraft: true, onSave: { _ in true }
    )
}
#Preview("Fertilizer Entry", traits: .sizeThatFitsLayout) {
    @Previewable @State var draft = FertilizerDraft(record: GardenPreviewData.fertilizers[0])
    FertilizerEntryCard(draft: $draft, onSelectType: {}).padding().frame(width: 402)
}
#Preview("Panen · Default", traits: .fixedLayout(width: 402, height: 721)) {
    HarvestHistoryScreen(record: nil, onSave: { _ in true })
}
#endif
