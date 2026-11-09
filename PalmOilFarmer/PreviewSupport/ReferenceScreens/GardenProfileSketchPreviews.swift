#if DEBUG
import SwiftUI

private enum ProfileSketchFixture {
    static var garden: Garden {
        Garden(id: UUID(), name: "Belakang Rumah", locationName: "Malang Rapat, Bintan, Kep. Riau",
               boundary: GardenPreviewData.boundary, plantingYear: 2012, soilType: .peat)
    }

    static var complete: Garden {
        var garden = garden
        garden.fertilizerRecords = GardenPreviewData.fertilizers
        garden.harvestRecord = HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 140, averageMonthlyWeightKg: 420)
        garden.fertilizationFrequencyPerYear = 2
        return garden
    }

    static func content(complete: Bool) -> some View {
        GardenProfileContentView(garden: complete ? self.complete : garden,
                             referenceMapImage: "ProfileReferenceSatellite",
                             metrics: GardenPreviewData.metrics, currentReviewStatus: nil, isComplete: complete,
                             onBack: {}, onEditGarden: {}, onEditProfile: {}, onReviewAction: {},
                    onViewSummary: {}, onViewReviewInformation: {})
    }

    static var editor: GardenProfileEditorViewModel {
        let model = GardenProfileEditorViewModel(garden: garden, onSave: { _, _, _ in true }, onSaved: {})
        var npk = FertilizerInputDraft()
        npk.name = "NPK"
        npk.doseKgPerTree = 0.5
        npk.composition = FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15)
        model.fertilizers = [npk, FertilizerInputDraft()]
        return model
    }
}

#Preview("Sketch · Missing History") { ProfileSketchFixture.content(complete: false) }
#Preview("Sketch · Profil Lengkap") { ProfileSketchFixture.content(complete: true) }
#Preview("Sketch · Formulir Profil", traits: .fixedLayout(width: 402, height: 1328)) {
    GardenProfileEditorView(model: ProfileSketchFixture.editor, onClose: {})
}
#Preview("Sketch · Ringkasan Profil", traits: .fixedLayout(width: 402, height: 956)) {
    GardenProfileSummaryView(garden: ProfileSketchFixture.complete, onClose: {}, onEdit: {})
}
#Preview("Sketch · Peninjauan Kebun", traits: .fixedLayout(width: 402, height: 962)) {
    GardenReviewInformationView(onClose: {}, onApply: {})
}
#Preview("Profil · Dynamic Type") {
    GardenProfileEditorView(model: ProfileSketchFixture.editor, onClose: {})
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
