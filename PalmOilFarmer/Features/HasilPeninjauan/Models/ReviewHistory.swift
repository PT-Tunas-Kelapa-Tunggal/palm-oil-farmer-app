import Foundation

/// Display data for the garden's fertilizer and harvest history.
struct ReviewHistory {
    struct Fertilizer: Identifiable {
        let name: String
        let bagWeight: String
        let bagCount: String
        let dose: String
        var id: String { name }
    }

    let fertilizers: [Fertilizer]
    let fertilizingFrequency: Int
    let harvestFrequency: String
    let averageHarvest: String
}

#if DEBUG
extension ReviewHistory {
    /// Example values from the design.
    static let sample = ReviewHistory(
        fertilizers: [
            Fertilizer(name: "Dolomit Super", bagWeight: "50kg", bagCount: "6 karung", dose: "1 kg / pohon"),
            Fertilizer(name: "Urea", bagWeight: "50kg", bagCount: "6 karung", dose: "0,5 kg / pohon"),
            Fertilizer(name: "NPK 15-15-15", bagWeight: "50kg", bagCount: "6 karung", dose: "0,5 kg / pohon")
        ],
        fertilizingFrequency: 2,
        harvestFrequency: "3 kali per bulan",
        averageHarvest: "420kg"
    )
}
#endif
