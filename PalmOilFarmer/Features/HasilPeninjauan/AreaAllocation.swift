import Foundation

/// Display data for one fertilizer's allocation across the garden's areas.
struct AreaAllocation {
    struct Fertilizer: Identifiable {
        let name: String
        let kilograms: Int
        var id: String { name }
    }

    enum Status {
        case fertilized, sameDose, increased

        var title: String {
            switch self {
            case .fertilized: "Sudah dipupuk"
            case .sameDose: "Dosis sama"
            case .increased: "Ditingkatkan"
            }
        }

        var systemImage: String {
            switch self {
            case .fertilized: "checkmark"
            case .sameDose: "arrow.right"
            case .increased: "chart.line.uptrend.xyaxis"
            }
        }
    }

    struct Line: Identifiable {
        let id: Int
        let kilograms: Int
        let dose: String
        let status: Status
    }

    let fertilizers: [Fertilizer]
    let selectedFertilizer: String
    let lines: [Line]
}

#if DEBUG
extension AreaAllocation {
    /// Example values from the design. The six areas add up to the 371 kg of Dolomit.
    static let sample = AreaAllocation(
        fertilizers: [
            Fertilizer(name: "Dolomit", kilograms: 371),
            Fertilizer(name: "NPK 15-15-15", kilograms: 391),
            Fertilizer(name: "Urea", kilograms: 135)
        ],
        selectedFertilizer: "Dolomit",
        lines: [
            Line(id: 1, kilograms: 83, dose: "1,5", status: .fertilized),
            Line(id: 2, kilograms: 48, dose: "1,0", status: .sameDose),
            Line(id: 3, kilograms: 52, dose: "1,0", status: .sameDose),
            Line(id: 4, kilograms: 90, dose: "1,5", status: .increased),
            Line(id: 5, kilograms: 50, dose: "1,0", status: .sameDose),
            Line(id: 6, kilograms: 48, dose: "1,0", status: .sameDose)
        ]
    )
}
#endif
