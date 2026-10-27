#if DEBUG
import SwiftUI

#Preview("CodedUI2 · Referensi Nitrogen") {
    if let reference = RecommendationPreviewData.report.nutrientReferences.first {
        NutrientReferenceScreen(reference: reference)
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
