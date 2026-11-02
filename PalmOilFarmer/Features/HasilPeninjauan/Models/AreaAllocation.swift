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
        var status: Status
        var photo: String? = nil
    }

    /// Extra explanation for a fertilizer that only some areas receive.
    struct Guidance {
        let title: String
        let message: String
        let footnote: String
    }

    /// A fertilizer is either dosed per area or spread evenly across the whole garden.
    enum Distribution {
        case perArea([Line], guidance: Guidance? = nil)
        case uniform(dose: String, note: String, isFertilized: Bool = false)
    }

    let fertilizers: [Fertilizer]
    let selectedFertilizer: String
    let distribution: Distribution

    /// A nil `areaID` marks the whole garden, which applies to even spreading.
    func markingFertilized(areaID: Int?) -> AreaAllocation {
        let updated: Distribution
        switch distribution {
        case .perArea(let lines, let guidance):
            updated = .perArea(lines.map { line in
                var line = line
                if line.id == areaID { line.status = .fertilized }
                return line
            }, guidance: guidance)
        case .uniform(let dose, let note, let isFertilized):
            updated = .uniform(dose: dose, note: note, isFertilized: isFertilized || areaID == nil)
        }
        return AreaAllocation(fertilizers: fertilizers, selectedFertilizer: selectedFertilizer, distribution: updated)
    }
}

#if DEBUG
extension AreaAllocation {
    /// Example values from the design. The six areas add up to the 371 kg of Dolomit.
    static let sample = AreaAllocation(
        fertilizers: sampleFertilizers,
        selectedFertilizer: "Dolomit",
        distribution: .perArea([
            Line(id: 1, kilograms: 83, dose: "1,5", status: .fertilized),
            Line(id: 2, kilograms: 48, dose: "1,0", status: .sameDose),
            Line(id: 3, kilograms: 52, dose: "1,0", status: .sameDose),
            Line(id: 4, kilograms: 90, dose: "1,5", status: .increased),
            Line(id: 5, kilograms: 50, dose: "1,0", status: .sameDose),
            Line(id: 6, kilograms: 48, dose: "1,0", status: .sameDose)
        ])
    )

    static let uniformSample = AreaAllocation(
        fertilizers: sampleFertilizers,
        selectedFertilizer: "NPK 15-15-15",
        distribution: .uniform(
            dose: "1,25",
            note: "Dosis sama untuk semua pohon di seluruh kebun. Tidak perlu mencari area tertentu."
        )
    )

    /// The four areas add up to the 135 kg of Urea.
    static let ureaSample = AreaAllocation(
        fertilizers: sampleFertilizers,
        selectedFertilizer: "Urea",
        distribution: .perArea(
            [
                Line(id: 1, kilograms: 41, dose: "0,75", status: .fertilized),
                .ureaAreaTwo,
                Line(id: 4, kilograms: 45, dose: "0,75", status: .increased),
                Line(id: 5, kilograms: 25, dose: "0,5", status: .sameDose)
            ],
            guidance: Guidance(
                title: "Pupuk sesuai kondisi area",
                message: "Setiap area mendapat jenis dan dosis pupuk yang berbeda. Tandai setelah selesai dipupuk.",
                footnote: "Area 3 dan 6 tidak perlu pupuk tambahan."
            )
        )
    )

    private static let sampleFertilizers = [
        Fertilizer(name: "Dolomit", kilograms: 371),
        Fertilizer(name: "NPK 15-15-15", kilograms: 391),
        Fertilizer(name: "Urea", kilograms: 135)
    ]
}

extension AreaAllocation.Line {
    static let ureaAreaTwo = AreaAllocation.Line(id: 2, kilograms: 24, dose: "0,5", status: .sameDose)
}
#endif
