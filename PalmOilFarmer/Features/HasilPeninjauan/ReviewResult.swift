import Foundation

/// Display data for the main review result screen.
struct ReviewResult {
    struct Metric: Identifiable {
        let title: String
        let value: String
        var id: String { title }
    }

    enum NutrientStatus {
        case belowNormal, normal, deficient

        var title: String {
            switch self {
            case .belowNormal: "Di Bawah Normal"
            case .normal: "Normal"
            case .deficient: "Defisiensi"
            }
        }

        var systemImage: String {
            self == .normal ? "checkmark.circle.fill" : "chevron.down.circle.fill"
        }
    }

    struct Nutrient: Identifiable {
        let name: String
        let symbol: String
        let kilograms: Int
        let status: NutrientStatus
        var id: String { symbol }
    }

    struct BudgetLine: Identifiable {
        let name: String
        let kilograms: Int
        let price: String
        var id: String { name }
    }

    /// Points are fractions of the map image, so the outline scales with it.
    struct Area: Identifiable {
        let id: Int
        let outline: [CGPoint]

        var center: CGPoint {
            CGPoint(x: outline.map(\.x).reduce(0, +) / CGFloat(outline.count),
                    y: outline.map(\.y).reduce(0, +) / CGFloat(outline.count))
        }
    }

    let gardenName: String
    let locationName: String
    let mapImage: String
    let areas: [Area]
    let metrics: [Metric]
    let nutrients: [Nutrient]
    let summary: String
    let budgetLines: [BudgetLine]
}

#if DEBUG
extension ReviewResult {
    /// Example values from the design. Pixel positions match the 1206×1140 `CodedProfileMap` image.
    static let sample: ReviewResult = {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x / 1206, y: y / 1140)
        }
        let topLeft = point(482, 523), notch = point(616, 577), topMiddle = point(650, 507)
        let topRight = point(786, 556), bottomRight = point(594, 958), bottomLeft = point(492, 904)
        let waist = point(536, 796), left = point(403, 733)
        let leftMiddle = point(442, 628), center = point(576, 686)
        let rightUpper = point(722, 690), rightLower = point(659, 821)

        return ReviewResult(
            gardenName: "Belakang Rumah",
            locationName: "Malang Rapat, Bintan, Kep. Riau",
            mapImage: "CodedProfileMap",
            areas: [
                Area(id: 1, outline: [leftMiddle, center, waist, left]),
                Area(id: 2, outline: [topLeft, notch, center, leftMiddle]),
                Area(id: 3, outline: [notch, topMiddle, topRight, rightUpper, center]),
                Area(id: 4, outline: [center, rightUpper, rightLower, waist]),
                Area(id: 5, outline: [waist, rightLower, bottomRight, bottomLeft])
            ],
            metrics: [
                Metric(title: "Luas tanah", value: "2,3 ha"),
                Metric(title: "Perimeter", value: "2300 m"),
                Metric(title: "Tahun Tanam", value: "2012")
            ],
            nutrients: [
                Nutrient(name: "Nitrogen", symbol: "N", kilograms: 30, status: .belowNormal),
                Nutrient(name: "Fosfor", symbol: "P", kilograms: 6, status: .normal),
                Nutrient(name: "Kalium", symbol: "K", kilograms: 30, status: .deficient),
                Nutrient(name: "Magnesium", symbol: "Mg", kilograms: 6, status: .normal)
            ],
            summary: "Dosis pupuk kebun ini masih di bawah kebutuhan dan komposisinya belum seimbang. Area 1 dan 4 paling perlu diperhatikan.",
            budgetLines: [
                BudgetLine(name: "Dolomit", kilograms: 371, price: "Rp556.500"),
                BudgetLine(name: "NPK 15-15-15", kilograms: 391, price: "Rp5.083.000"),
                BudgetLine(name: "Urea", kilograms: 135, price: "Rp1.215.000")
            ]
        )
    }()
}
#endif
