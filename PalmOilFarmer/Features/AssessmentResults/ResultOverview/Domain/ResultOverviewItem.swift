import Foundation

/// Timeline period capsule for the fertilizer recommendation card.
public struct FertilizerPeriodItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let orderText: String
    public let month: String
    public let year: String

    public init(id: String, orderText: String, month: String, year: String) {
        self.id = id
        self.orderText = orderText
        self.month = month
        self.year = year
    }
}

/// Nutrient status condition level.
public enum NutrientConditionStatus: String, Equatable, Sendable {
    case kurang = "Kurang"
    case berlebih = "Berlebih"
    case cukup = "Cukup"
}

/// Summary item representing one nutrient status chip (N, P, K, Mg).
public struct NutrientStatusSummaryItem: Identifiable, Equatable, Sendable {
    public var id: String { symbol }
    public let symbol: String
    public let name: String
    public let status: NutrientConditionStatus

    public init(symbol: String, name: String, status: NutrientConditionStatus) {
        self.symbol = symbol
        self.name = name
        self.status = status
    }
}

/// Metric summary for the garden greenness (Kehijauan Kebun) card.
public struct FarmGreennessSummary: Equatable, Sendable {
    public let affectedTreeCount: Int
    public let totalTreeCount: Int
    public let statusDescription: String

    public init(affectedTreeCount: Int, totalTreeCount: Int, statusDescription: String) {
        self.affectedTreeCount = affectedTreeCount
        self.totalTreeCount = totalTreeCount
        self.statusDescription = statusDescription
    }
}

/// Cost overview summary for the fertilizer estimation card.
public struct FertilizerEstimationSummary: Equatable, Sendable {
    public let totalCost: Int
    public let fertilizerTypeCount: Int
    public let budgetLimit: Int

    public init(totalCost: Int, fertilizerTypeCount: Int, budgetLimit: Int) {
        self.totalCost = totalCost
        self.fertilizerTypeCount = fertilizerTypeCount
        self.budgetLimit = budgetLimit
    }

    public var isUnderBudget: Bool {
        totalCost <= budgetLimit
    }

    public var formattedTotalCost: String {
        formatRupiah(totalCost)
    }

    public var formattedBudgetLimit: String {
        formatRupiah(budgetLimit)
    }

    private func formatRupiah(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: NSNumber(value: value)) ?? "Rp\(value)"
    }
}

/// A list item row in the locked "Data Kebun" section.
public struct GardenDataSummaryRowItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let iconSystemName: String
    public let isLocked: Bool

    public init(
        id: String,
        title: String,
        subtitle: String,
        iconSystemName: String,
        isLocked: Bool = true
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.isLocked = isLocked
    }
}

/// Full domain entity representing the assessment results hub (Ringkasan Hasil).
public struct ResultOverviewItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let gardenName: String
    public let locationName: String
    public let heroImageName: String?
    public let recommendationTitle: String
    public let recommendationSubtitle: String
    public let periods: [FertilizerPeriodItem]
    public let nutrientStatusTitle: String
    public let nutrientStatusSummary: String
    public let nutrients: [NutrientStatusSummaryItem]
    public let greenness: FarmGreennessSummary
    public let fertilizerEstimation: FertilizerEstimationSummary
    public let gardenDataRows: [GardenDataSummaryRowItem]

    public func replacingGardenDetails(
        name: String?,
        location: String?,
        greenness: FarmGreennessSummary? = nil
    ) -> ResultOverviewItem {
        ResultOverviewItem(
            id: id,
            gardenName: name.flatMap { $0.isEmpty ? nil : $0 } ?? gardenName,
            locationName: location.flatMap { $0.isEmpty ? nil : $0 } ?? locationName,
            heroImageName: heroImageName,
            recommendationTitle: recommendationTitle,
            recommendationSubtitle: recommendationSubtitle,
            periods: periods,
            nutrientStatusTitle: nutrientStatusTitle,
            nutrientStatusSummary: nutrientStatusSummary,
            nutrients: nutrients,
            greenness: greenness ?? self.greenness,
            fertilizerEstimation: fertilizerEstimation,
            gardenDataRows: gardenDataRows
        )
    }

    public init(
        id: String,
        gardenName: String,
        locationName: String,
        heroImageName: String? = nil,
        recommendationTitle: String = "Rekomendasi Pemupukan",
        recommendationSubtitle: String = "3 kali pemupukan di tahun 2027",
        periods: [FertilizerPeriodItem],
        nutrientStatusTitle: String = "Belum Seimbang",
        nutrientStatusSummary: String = "Hasil dari praktik pemupukan Anda sebelumnya: dua hara kurang dan satu berlebih.",
        nutrients: [NutrientStatusSummaryItem],
        greenness: FarmGreennessSummary,
        fertilizerEstimation: FertilizerEstimationSummary,
        gardenDataRows: [GardenDataSummaryRowItem]
    ) {
        self.id = id
        self.gardenName = gardenName
        self.locationName = locationName
        self.heroImageName = heroImageName
        self.recommendationTitle = recommendationTitle
        self.recommendationSubtitle = recommendationSubtitle
        self.periods = periods
        self.nutrientStatusTitle = nutrientStatusTitle
        self.nutrientStatusSummary = nutrientStatusSummary
        self.nutrients = nutrients
        self.greenness = greenness
        self.fertilizerEstimation = fertilizerEstimation
        self.gardenDataRows = gardenDataRows
    }
}

// MARK: - Sample Fixtures

extension ResultOverviewItem {
    /// Sample data matching Sketch artboard: "Hasil Peninjauan / Ringkasan Hasil / Default"
    public static let sample = ResultOverviewItem(
        id: "res-overview-default",
        gardenName: "Belakang Rumah",
        locationName: "Malang Rapat, Bintan",
        heroImageName: "ResultOverviewMap",
        recommendationTitle: "Rekomendasi Pemupukan",
        recommendationSubtitle: "3 kali pemupukan di tahun 2027",
        periods: [
            FertilizerPeriodItem(id: "p1", orderText: "Pertama", month: "Jan", year: "2027"),
            FertilizerPeriodItem(id: "p2", orderText: "Kedua", month: "Apr", year: "2027"),
            FertilizerPeriodItem(id: "p3", orderText: "Ketiga", month: "Jul", year: "2027")
        ],
        nutrientStatusTitle: "Belum Seimbang",
        nutrientStatusSummary: "Hasil dari praktik pemupukan Anda sebelumnya: dua hara kurang dan satu berlebih.",
        nutrients: [
            NutrientStatusSummaryItem(symbol: "N", name: "Nitrogen", status: .kurang),
            NutrientStatusSummaryItem(symbol: "P", name: "Fosfor", status: .berlebih),
            NutrientStatusSummaryItem(symbol: "K", name: "Kalium", status: .kurang),
            NutrientStatusSummaryItem(symbol: "Mg", name: "Magnesium", status: .cukup)
        ],
        greenness: FarmGreennessSummary(
            affectedTreeCount: 108,
            totalTreeCount: 228,
            statusDescription: "dari 228 pohon terindikasi kekurangan nutrisi"
        ),
        fertilizerEstimation: FertilizerEstimationSummary(
            totalCost: 7850000,
            fertilizerTypeCount: 3,
            budgetLimit: 9350000
        ),
        gardenDataRows: [
            GardenDataSummaryRowItem(
                id: "identity",
                title: "Identitas Kebun",
                subtitle: "Lokasi, luas, tahun tanam, jenis tanah",
                iconSystemName: "square.dashed.inset.filled",
                isLocked: true
            ),
            GardenDataSummaryRowItem(
                id: "logs",
                title: "Riwayat Panen dan Pemupukan",
                subtitle: "Dasar perhitungan kondisi hara",
                iconSystemName: "doc.text",
                isLocked: true
            ),
            GardenDataSummaryRowItem(
                id: "request",
                title: "Pengajuan Peninjauan",
                subtitle: "Narahubung dan tanggal pengajuan",
                iconSystemName: "paperplane",
                isLocked: true
            )
        ]
    )
}

