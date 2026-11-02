import Foundation

/// Fixed content for one nutrient. Garden-specific kilograms are passed to the view separately.
struct NutrientDetail {
    struct Fertilizer: Identifiable {
        let name: String
        let content: String
        var id: String { name }
    }

    enum Status {
        case below, matched, above

        init(currentKg: Double, needKg: Double) {
            if currentKg < needKg {
                self = .below
            } else if currentKg > needKg {
                self = .above
            } else {
                self = .matched
            }
        }

        var emphasis: String {
            switch self {
            case .below: "masih di bawah ideal"
            case .matched: "sudah sesuai kebutuhan"
            case .above: "sudah melebihi kebutuhan"
            }
        }

        var advice: String {
            switch self {
            case .below: "Ikuti rekomendasi pemupukan untuk mencapai dosis ideal pada kebun Anda."
            case .matched: "Pertahankan dosis pemupukan saat ini."
            case .above: "Ikuti rekomendasi pemupukan untuk menyesuaikan dosis pada kebun Anda."
            }
        }
    }

    let name: String
    let symbol: String
    let role: String
    let fertilizers: [Fertilizer]

    static let nitrogen = NutrientDetail(
        name: "Nitrogen", symbol: "N",
        role: "Nitrogen membantu daun tetap hijau dan pelepah baru tumbuh.",
        fertilizers: [
            Fertilizer(name: "Urea", content: "Kandungan nitrogen ±46%."),
            Fertilizer(name: "ZA", content: "Kandungan nitrogen ±21%, juga mengandung belerang."),
            Fertilizer(name: "NPK 15-15-15", content: "Kandungan nitrogen ±15%, juga mengandung fosfor dan kalium.")
        ]
    )

    static let phosphorus = NutrientDetail(
        name: "Fosfor", symbol: "P",
        role: "Fosfor membantu akar tumbuh kuat serta pembentukan bunga dan buah.",
        fertilizers: [
            Fertilizer(name: "SP-36", content: "Kandungan fosfor ±36%."),
            Fertilizer(name: "TSP", content: "Kandungan fosfor ±46%."),
            Fertilizer(name: "NPK 15-15-15", content: "Kandungan fosfor ±15%, juga mengandung nitrogen dan kalium.")
        ]
    )

    static let potassium = NutrientDetail(
        name: "Kalium", symbol: "K",
        role: "Kalium membantu buah terisi penuh dan tanaman lebih tahan kekeringan.",
        fertilizers: [
            Fertilizer(name: "KCl", content: "Kandungan kalium ±60%."),
            Fertilizer(name: "NPK 15-15-15", content: "Kandungan kalium ±15%, juga mengandung nitrogen dan fosfor.")
        ]
    )

    static let magnesium = NutrientDetail(
        name: "Magnesium", symbol: "Mg",
        role: "Magnesium membantu daun tetap hijau dan mencegah daun tua menguning.",
        fertilizers: [
            Fertilizer(name: "Kieserit", content: "Kandungan magnesium ±27%, juga mengandung belerang."),
            Fertilizer(name: "Dolomit", content: "Kandungan magnesium ±18%, juga mengandung kalsium.")
        ]
    )
}
