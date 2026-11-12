import Foundation

/// Domain model representing the entire nutrient condition report for a garden.
public struct NutrientConditionOverview: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let nutrients: [NutrientItem]

    public init(
        id: String,
        title: String,
        subtitle: String,
        nutrients: [NutrientItem]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.nutrients = nutrients
    }
}

/// Status of an individual nutrient evaluation.
public enum NutrientStatus: String, CaseIterable, Equatable, Sendable {
    case deficient = "Kurang"
    case excess = "Berlebih"
    case sufficient = "Cukup"

    public var displayName: String {
        rawValue
    }
}

/// Side-by-side comparison between current fertilization practice and recommended requirement.
public struct NutrientComparison: Equatable, Sendable {
    public let currentPracticeValue: Int
    public let currentPracticeLabel: String
    public let requiredValue: Int
    public let requiredLabel: String
    public let unit: String

    public init(
        currentPracticeValue: Int,
        currentPracticeLabel: String = "Praktik saat ini",
        requiredValue: Int,
        requiredLabel: String = "Kebutuhan",
        unit: String = "kg"
    ) {
        self.currentPracticeValue = currentPracticeValue
        self.currentPracticeLabel = currentPracticeLabel
        self.requiredValue = requiredValue
        self.requiredLabel = requiredLabel
        self.unit = unit
    }
}

/// Domain model representing a single nutrient assessment card (e.g. Nitrogen, Phosphorus, Potassium, Magnesium).
public struct NutrientItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let symbol: String
    public let title: String
    public let sourceDescription: String
    public let status: NutrientStatus
    public let description: String
    public let comparison: NutrientComparison?
    public let verdict: String
    public let warningImpact: String?

    public init(
        id: String,
        name: String,
        symbol: String,
        title: String,
        sourceDescription: String,
        status: NutrientStatus,
        description: String,
        comparison: NutrientComparison? = nil,
        verdict: String,
        warningImpact: String? = nil
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.title = title
        self.sourceDescription = sourceDescription
        self.status = status
        self.description = description
        self.comparison = comparison
        self.verdict = verdict
        self.warningImpact = warningImpact
    }
}

// MARK: - Sample Data Fixtures

extension NutrientConditionOverview {
    /// Sample data matching the Sketch design: "Hasil Peninjauan / Kondisi Hara / Feed"
    public static let dummyData = NutrientConditionOverview(
        id: "garden-assessment-1",
        title: "Kondisi Hara",
        subtitle: "Belum seimbang, dihitung per tahun untuk seluruh kebun",
        nutrients: [
            NutrientItem(
                id: "nitrogen",
                name: "Nitrogen",
                symbol: "N",
                title: "Nitrogen (N)",
                sourceDescription: "Perkiraan dari riwayat pupuk",
                status: .deficient,
                description: "Nitrogen membantu daun tetap hijau dan pelepah baru tumbuh.",
                comparison: NutrientComparison(
                    currentPracticeValue: 173,
                    currentPracticeLabel: "Praktik saat ini",
                    requiredValue: 190,
                    requiredLabel: "Kebutuhan",
                    unit: "kg"
                ),
                verdict: "Praktik pemupukan Anda masih di bawah kebutuhan.",
                warningImpact: "Kekurangan nitrogen membuat pelepah menguning dan jumlah pelepah baru berkurang."
            ),
            NutrientItem(
                id: "fosfor",
                name: "Fosfor",
                symbol: "P",
                title: "Fosfor (P)",
                sourceDescription: "Perkiraan dari riwayat pupuk",
                status: .excess,
                description: "Fosfor membantu pertumbuhan akar dan pembentukan bunga.",
                comparison: NutrientComparison(
                    currentPracticeValue: 68,
                    currentPracticeLabel: "Praktik saat ini",
                    requiredValue: 52,
                    requiredLabel: "Kebutuhan",
                    unit: "kg"
                ),
                verdict: "Praktik pemupukan Anda melebihi kebutuhan.",
                warningImpact: "Fosfor berlebih tidak menambah hasil panen dan membuat biaya pupuk terbuang."
            ),
            NutrientItem(
                id: "kalium",
                name: "Kalium",
                symbol: "K",
                title: "Kalium (K)",
                sourceDescription: "Perkiraan dari riwayat pupuk",
                status: .deficient,
                description: "Kalium membantu buah terbentuk penuh dan pohon tahan kekeringan.",
                comparison: NutrientComparison(
                    currentPracticeValue: 68,
                    currentPracticeLabel: "Praktik saat ini",
                    requiredValue: 90,
                    requiredLabel: "Kebutuhan",
                    unit: "kg"
                ),
                verdict: "Praktik pemupukan Anda masih di bawah kebutuhan.",
                warningImpact: "Kekurangan kalium membuat tandan lebih kecil dan muncul bercak pada daun tua."
            ),
            NutrientItem(
                id: "magnesium",
                name: "Magnesium",
                symbol: "Mg",
                title: "Magnesium (Mg)",
                sourceDescription: "Perkiraan dari riwayat pupuk",
                status: .sufficient,
                description: "Magnesium membantu daun membentuk zat hijau daun.",
                comparison: NutrientComparison(
                    currentPracticeValue: 54,
                    currentPracticeLabel: "Praktik saat ini",
                    requiredValue: 52,
                    requiredLabel: "Kebutuhan",
                    unit: "kg"
                ),
                verdict: "Magnesium di kebun Anda sudah cukup. Tidak perlu pupuk tambahan.",
                warningImpact: nil
            )
        ]
    )
}

