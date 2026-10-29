#if DEBUG
import SwiftUI

#Preview("CodedUI2 · Referensi Nitrogen") {
    let report = RecommendationPreviewData.report
    if let reference = report.nutrientReferences.first,
       let projection = report.nutrients.first(where: { $0.name == reference.id }) {
        NutrientReferenceScreen(
            reference: reference,
            projection: projection,
            currentLabel: report.currentNutrientLabel ?? "NPK riwayat",
            targetLabel: report.targetNutrientLabel ?? "Rekomendasi NPKMg",
        )
    }
}

#Preview("CodedUI2 · Pilih Area") {
    @Previewable @State var selectedAreaID = "AB"
    RecommendationAreaPickerScreen(areas: RecommendationPreviewData.report.areas, selectedAreaID: $selectedAreaID)
}

#Preview("CodedUI2 · Pengajuan ke Formulir") {
    @Previewable @State var showsForm = false
    NavigationStack {
        ReviewRequestScreen { showsForm = true }
            .navigationDestination(isPresented: $showsForm) {
                ReviewContactFormScreen { _ in throw ReviewServiceError.unavailable }
            }
    }
}

#Preview("CodedUI2 · Hasil peninjauan") {
    NavigationStack {
        GardenProfileScreen(garden: GardenPreviewData.completedGarden,
                          referenceMapImage: "CodedProfileMap", metrics: GardenPreviewData.metrics,
                          reviewStatus: .completed,
                          reviewEntries: ReviewTimelineEntry.referenceEntries(for: .completed),
                          recommendationReport: RecommendationPreviewData.report, onUpdate: { _ in true })
    }
}
#endif
