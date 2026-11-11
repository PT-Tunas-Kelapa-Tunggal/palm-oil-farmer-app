import Foundation

/// Domain model representing an option in the NPK formulation picker.
public struct NPKOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let weightKg: Int
    public let bagCount: Int
    public let pricePerBag: Int
    public let totalPrice: Int
    public let tag: String?
    public let savingsDifference: Int?

    public init(
        id: String,
        name: String,
        weightKg: Int,
        bagCount: Int,
        pricePerBag: Int,
        totalPrice: Int,
        tag: String? = nil,
        savingsDifference: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.weightKg = weightKg
        self.bagCount = bagCount
        self.pricePerBag = pricePerBag
        self.totalPrice = totalPrice
        self.tag = tag
        self.savingsDifference = savingsDifference
    }

    public var formattedPrice: String {
        CurrencyFormatter.formatRupiah(totalPrice)
    }

    public var subtitle: String {
        var text = "\(weightKg) kg, \(formattedPrice)"
        if let tag {
            text += "\n\(tag)"
        }
        return text
    }
}

/// Domain model representing a single row in the fertilizer shopping table.
public struct FertilizerItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let pricePerBag: Int
    public let bagWeightKg: Int
    public let weightKg: Int
    public let bagCount: Int
    public let totalPrice: Int
    public let isCustomizableNPK: Bool
    public let savingsHint: String?

    public init(
        id: String,
        name: String,
        pricePerBag: Int,
        bagWeightKg: Int = 50,
        weightKg: Int,
        bagCount: Int,
        totalPrice: Int,
        isCustomizableNPK: Bool = false,
        savingsHint: String? = nil
    ) {
        self.id = id
        self.name = name
        self.pricePerBag = pricePerBag
        self.bagWeightKg = bagWeightKg
        self.weightKg = weightKg
        self.bagCount = bagCount
        self.totalPrice = totalPrice
        self.isCustomizableNPK = isCustomizableNPK
        self.savingsHint = savingsHint
    }

    public var formattedPricePerBag: String {
        "\(CurrencyFormatter.formatRupiah(pricePerBag))/sak"
    }

    public var formattedTotalPrice: String {
        CurrencyFormatter.formatRupiah(totalPrice)
    }
}

/// Domain model representing the full fertilizer cost estimate report for a garden.
public struct FertilizerEstimationOverview: Identifiable, Equatable, Sendable {
    public let id: String
    public let gardenName: String
    public let periodDescription: String
    public let budgetLimit: Int
    public let fertilizers: [FertilizerItem]
    public let npkOptions: [NPKOption]
    public let selectedNPKId: String
    public let defaultNPKId: String
    public let footnote: String

    public init(
        id: String,
        gardenName: String,
        periodDescription: String = "untuk kebutuhan 1 tahun",
        budgetLimit: Int = 9350000,
        fertilizers: [FertilizerItem],
        npkOptions: [NPKOption],
        selectedNPKId: String,
        defaultNPKId: String = "npk-15",
        footnote: String = "Harga perkiraan per sak 50 kg di toko pertanian sekitar Bintan, November 2026. Harga di toko bisa berbeda."
    ) {
        self.id = id
        self.gardenName = gardenName
        self.periodDescription = periodDescription
        self.budgetLimit = budgetLimit
        self.fertilizers = fertilizers
        self.npkOptions = npkOptions
        self.selectedNPKId = selectedNPKId
        self.defaultNPKId = defaultNPKId
        self.footnote = footnote
    }

    public var isNPKChangedFromDefault: Bool {
        selectedNPKId != defaultNPKId
    }

    public var totalCost: Int {
        fertilizers.reduce(0) { $0 + $1.totalPrice }
    }

    public var remainingBudget: Int {
        max(0, budgetLimit - totalCost)
    }

    public var budgetProgress: Double {
        guard budgetLimit > 0 else { return 0 }
        return min(1.0, Double(totalCost) / Double(budgetLimit))
    }

    public var formattedTotalCost: String {
        CurrencyFormatter.formatRupiah(totalCost)
    }

    public var formattedBudgetLimit: String {
        CurrencyFormatter.formatRupiah(budgetLimit)
    }

    public var formattedRemainingBudget: String {
        CurrencyFormatter.formatRupiah(remainingBudget)
    }
}

// MARK: - Currency Helper

public enum CurrencyFormatter {
    public static func formatRupiah(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: NSNumber(value: value)) ?? "Rp\(value)"
    }
}

// MARK: - Sample Data Fixtures

extension FertilizerEstimationOverview {
    /// Sample data matching the Sketch design: "Hasil Peninjauan / Perkiraan Biaya Pupuk / Default"
    public static let sample = FertilizerEstimationOverview(
        id: "est-1",
        gardenName: "Kebun Belakang Rumah",
        periodDescription: "untuk kebutuhan 1 tahun",
        budgetLimit: 9350000,
        fertilizers: [
            FertilizerItem(
                id: "dolomit",
                name: "Dolomit",
                pricePerBag: 75000,
                bagWeightKg: 50,
                weightKg: 400,
                bagCount: 8,
                totalPrice: 600000
            ),
            FertilizerItem(
                id: "npk",
                name: "NPK 15-15-15",
                pricePerBag: 650000,
                bagWeightKg: 50,
                weightKg: 350,
                bagCount: 7,
                totalPrice: 4550000,
                isCustomizableNPK: true,
                savingsHint: "Ada pilihan NPK yang Rp350.000 lebih hemat."
            ),
            FertilizerItem(
                id: "urea",
                name: "Urea",
                pricePerBag: 450000,
                bagWeightKg: 50,
                weightKg: 300,
                bagCount: 6,
                totalPrice: 2700000
            )
        ],
        npkOptions: [
            NPKOption(
                id: "npk-15",
                name: "NPK 15-15-15",
                weightKg: 350,
                bagCount: 7,
                pricePerBag: 650000,
                totalPrice: 4550000
            ),
            NPKOption(
                id: "npk-16",
                name: "NPK 16-16-16",
                weightKg: 330,
                bagCount: 7,
                pricePerBag: 700000,
                totalPrice: 4900000
            ),
            NPKOption(
                id: "npk-12",
                name: "NPK 12-12-17-2",
                weightKg: 310,
                bagCount: 7,
                pricePerBag: 600000,
                totalPrice: 4200000,
                tag: "Paling hemat",
                savingsDifference: 350000
            )
        ],
        selectedNPKId: "npk-15",
        footnote: "Harga perkiraan per sak 50 kg di toko pertanian sekitar Bintan, November 2026. Harga di toko bisa berbeda."
    )
}

