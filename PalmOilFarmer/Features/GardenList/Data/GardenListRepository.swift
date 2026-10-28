import Foundation
import CoreLocation

protocol GardenListRepository {
    var gardens: [Garden] { get }
}

/// In-memory sample source for previews and local UI work. It never reads or writes
/// the app's persisted garden file.
struct DummyGardenListRepository: GardenListRepository {
    private(set) var gardens: [Garden]

    init(gardens: [Garden] = Self.sampleGardens) {
        self.gardens = gardens
    }

    mutating func update(_ garden: Garden) -> Bool {
        guard let index = gardens.firstIndex(where: { $0.id == garden.id }) else { return false }
        gardens[index] = garden
        return true
    }

    mutating func updateReview(_ review: GardenReview, for gardenID: UUID) -> Bool {
        guard var garden = gardens.first(where: { $0.id == gardenID }) else { return false }
        garden.review = review
        return update(garden)
    }

    mutating func delete(_ garden: Garden) -> Bool {
        guard gardens.contains(where: { $0.id == garden.id }) else { return false }
        gardens.removeAll { $0.id == garden.id }
        return true
    }

    private static let analyzedSampleGarden: Garden = {
        let garden = Garden(
            id: UUID(uuidString: "A91D5B38-1A74-4F02-8D18-1BC0D5A11A01")!,
            name: "Kebun Pak Sutrisno",
            locationName: "Bintan",
            boundary: GardenBoundary(points: [
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.66655, longitude: 101.44855)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.66655, longitude: 101.44945)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.66745, longitude: 101.44945)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.66745, longitude: 101.44855))
            ]),
            plantingYear: 2009,
            soilType: .mineral,
            fertilizerRecords: [
                FertilizerRecord(
                    name: "NPK 12-6-32",
                    bagWeightKg: 50,
                    bagCount: 6,
                    doseKgPerTree: 1,
                    npkComposition: NPKComposition(
                        nitrogenPercent: 12,
                        phosphatePercent: 6,
                        potashPercent: 32
                    )
                ),
                FertilizerRecord(
                    name: "Dolomit",
                    bagWeightKg: 50,
                    bagCount: 5,
                    doseKgPerTree: 0.5
                )
            ]
        )
        let geometry = FertilizerRecommendationReport.local(for: garden)
        let lines = [
            FertilizerAllocationLine(name: "Urea", total: "Total Urea dibutuhkan 8 kg", dosage: "0,25 kg / pohon"),
            FertilizerAllocationLine(name: "KCl (MOP)", total: "Total KCl dibutuhkan 6 kg", dosage: "0,20 kg / pohon"),
            FertilizerAllocationLine(name: "Kieserite", total: "Total Kieserite dibutuhkan 4 kg", dosage: "0,15 kg / pohon")
        ]
        let areas = ["AA", "BA", "AB", "BB", "AC", "BC"].map { areaID in
            FertilizerAllocationArea(id: areaID, mapImage: nil, periods: [
                FertilizerAllocationPeriod(title: "Pemupukan tahunan", dateRange: "November–Desember", lines: lines)
            ])
        }
        let report = FertilizerRecommendationReport(
            gardenName: garden.name,
            locationName: garden.locationName,
            boundary: garden.boundary,
            outline: geometry.outline,
            nutrients: [
                NutrientProjection(name: "N", current: 0.38, target: 0.64, status: "Kurang"),
                NutrientProjection(name: "P", current: 0.72, target: 0.64, status: "Cukup"),
                NutrientProjection(name: "K", current: 0.42, target: 0.64, status: "Kurang"),
                NutrientProjection(name: "Mg", current: 0.28, target: 0.64, status: "Rendah")
            ],
            costs: [
                FertilizerCostLine(name: "Urea", quantity: "48 kg", cost: "Rp360.000"),
                FertilizerCostLine(name: "KCl (MOP)", quantity: "36 kg", cost: "Rp420.000"),
                FertilizerCostLine(name: "Kieserite", quantity: "24 kg", cost: "Rp288.000")
            ],
            totalCost: "Rp1.068.000",
            areas: areas,
            nutrientSummary: "Nitrogen, kalium, dan magnesium masih di bawah target. Pupuk fosfor tambahan belum diperlukan."
        )
        var analyzedGarden = garden
        analyzedGarden.review = GardenReview(
            requestID: "dummy-analysis-\(garden.id.uuidString)",
            status: .completed,
            entries: ReviewTimelineEntry.referenceEntries(for: .completed),
            report: report,
            isLocalSimulation: false
        )
        return analyzedGarden
    }()

    static let sampleGardens: [Garden] = [analyzedSampleGarden]
}
