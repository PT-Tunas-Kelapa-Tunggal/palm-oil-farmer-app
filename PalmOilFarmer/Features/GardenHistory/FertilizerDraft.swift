import Foundation

struct FertilizerDraft: Identifiable {
    let id: UUID
    var name: String
    var bagWeightKg: Double?
    var bagCount: Int?
    var doseKgPerTree: Double?

    init(record: FertilizerRecord? = nil) {
        id = record?.id ?? UUID()
        name = record?.name ?? ""
        bagWeightKg = record?.bagWeightKg
        bagCount = record?.bagCount
        doseKgPerTree = record?.doseKgPerTree
    }

    var isEmpty: Bool {
        name.isEmpty && bagWeightKg == nil && bagCount == nil && doseKgPerTree == nil
    }

    var record: FertilizerRecord? {
        guard let bagWeightKg, let bagCount, let doseKgPerTree else { return nil }
        return FertilizerRecord.validated(id: id, name: name, bagWeightKg: bagWeightKg,
                                         bagCount: bagCount, doseKgPerTree: doseKgPerTree)
    }
}

enum FertilizerCatalogue {
    static let names = ["Urea", "ZA", "SP-36", "TSP", "KCl", "NPK", "Dolomit",
                        "Kieserit", "Borat", "Pupuk Organik", "Lainnya"]
}

