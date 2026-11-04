import Foundation

// MARK: - Domain: PlantationReviewRequest
public struct PlantationReviewRequest: Identifiable, Sendable {
    public let id: UUID
    public let farmer: FarmerContact
    public let garden: GardenSummary
    public let boundary: [CoordinatePoint]
    public let agronomy: AgronomicProfile
    public var status: ReviewStatus
    public var timeline: ReviewTimeline
    public var operatorNotes: String?
    public var result: PlantationReviewResult?

    public init(
        id: UUID = UUID(),
        farmer: FarmerContact,
        garden: GardenSummary,
        boundary: [CoordinatePoint],
        agronomy: AgronomicProfile,
        status: ReviewStatus = .submitted,
        timeline: ReviewTimeline = ReviewTimeline(),
        operatorNotes: String? = nil,
        result: PlantationReviewResult? = nil
    ) {
        self.id = id
        self.farmer = farmer
        self.garden = garden
        self.boundary = boundary
        self.agronomy = agronomy
        self.status = status
        self.timeline = timeline
        self.operatorNotes = operatorNotes
        self.result = result
    }
}

public struct FarmerContact: Sendable {
    public let name: String
    public let phone: String
    public let address: String

    public init(name: String, phone: String, address: String) {
        self.name = name
        self.phone = phone
        self.address = address
    }
}

public struct GardenSummary: Sendable {
    public let id: UUID
    public let name: String
    public let locationName: String
    public let areaHectares: Double

    public init(id: UUID, name: String, locationName: String, areaHectares: Double) {
        self.id = id
        self.name = name
        self.locationName = locationName
        self.areaHectares = areaHectares
    }
}

public struct CoordinatePoint: Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct AgronomicProfile: Sendable {
    public let plantingYear: Int
    public let plantingMonth: Int?
    public let soilType: String
    public let fertilizerRecords: [FertilizerUsage]
    public let harvestRecord: HarvestYield?

    public init(
        plantingYear: Int,
        plantingMonth: Int? = nil,
        soilType: String,
        fertilizerRecords: [FertilizerUsage] = [],
        harvestRecord: HarvestYield? = nil
    ) {
        self.plantingYear = plantingYear
        self.plantingMonth = plantingMonth
        self.soilType = soilType
        self.fertilizerRecords = fertilizerRecords
        self.harvestRecord = harvestRecord
    }
}

public struct FertilizerUsage: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let bagWeightKg: Double
    public let bagCount: Int
    public let doseKgPerTree: Double

    public init(
        id: UUID = UUID(),
        name: String,
        bagWeightKg: Double,
        bagCount: Int,
        doseKgPerTree: Double
    ) {
        self.id = id
        self.name = name
        self.bagWeightKg = bagWeightKg
        self.bagCount = bagCount
        self.doseKgPerTree = doseKgPerTree
    }
}

public struct HarvestYield: Sendable {
    public let frequencyPerMonth: Int
    public let latestWeightKg: Double

    public init(frequencyPerMonth: Int, latestWeightKg: Double) {
        self.frequencyPerMonth = frequencyPerMonth
        self.latestWeightKg = latestWeightKg
    }
}

// MARK: - Domain: ReviewTimeline
public struct ReviewTimeline: Sendable {
    public let submittedAt: Date
    public var scheduledFor: Date?
    public var inReviewAt: Date?
    public var completedAt: Date?

    public init(
        submittedAt: Date = Date(),
        scheduledFor: Date? = nil,
        inReviewAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.submittedAt = submittedAt
        self.scheduledFor = scheduledFor
        self.inReviewAt = inReviewAt
        self.completedAt = completedAt
    }

    func entries(for currentStatus: ReviewStatus) -> [ReviewTimelineEntry] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMMM yyyy HH:mm 'WIB'"

        let scheduledDateString = scheduledFor.map {
            let df = DateFormatter()
            df.locale = Locale(identifier: "id_ID")
            df.dateFormat = "EEEE, d MMMM yyyy"
            return df.string(from: $0)
        } ?? "jadwal yang disepakati"

        let titles = [
            "Permintaan Peninjauan\nBerhasil Diajukan",
            currentStatus.rawValue >= 1 ? "Kunjungan dijadwalkan" : "Penjadwalan Kunjungan",
            currentStatus.rawValue >= 2 ? "Peninjauan berlangsung" : "Peninjauan Kebun",
            currentStatus == .completed ? "Peninjauan Selesai" : "Pemrosesan Hasil Tinjauan"
        ]

        let messages = [
            "Permintaan Anda sudah dikirim. Petugas akan menghubungi Anda dalam 1 hari kerja untuk menentukan jadwal kunjungan ke kebun.",
            currentStatus.rawValue >= 1
                ? "Petugas akan datang ke kebun pada \(scheduledDateString). Pastikan Anda atau perwakilan dapat mendampingi di lokasi."
                : "Petugas dan Anda menyepakati hari kunjungan ke kebun.",
            currentStatus.rawValue >= 2
                ? "Petugas sudah mengunjungi kebun Anda. Hasil peninjauan sedang disusun dan akan muncul di sini dalam 1 hari kerja."
                : "Petugas datang ke kebun untuk memeriksa kondisi tanaman dan lahan.",
            currentStatus == .completed
                ? "Hasil peninjauan kebun Anda sudah tersedia. Analisis dan rekomendasi perawatan dapat dilihat di halaman Kebun."
                : "Sistem menyusun hasil kunjungan menjadi analisis dan rekomendasi perawatan."
        ]

        let dates: [String?] = [
            formatter.string(from: submittedAt),
            scheduledFor.map { formatter.string(from: $0) },
            inReviewAt.map { formatter.string(from: $0) },
            completedAt.map { formatter.string(from: $0) }
        ]

        return (0..<4).map { index in
            ReviewTimelineEntry(
                id: index,
                date: index <= currentStatus.rawValue ? dates[index] : nil,
                title: titles[index],
                message: messages[index],
                isReached: index <= currentStatus.rawValue
            )
        }
    }
}

// MARK: - Domain: PlantationReviewResult
public struct PlantationReviewResult: Sendable {
    public let completedAt: Date
    public let nutrients: [NutrientMetric]
    public let costs: [CostEstimate]
    public let totalCostFormatted: String
    public let allocationAreas: [FertilizerAreaPlan]
    public let orthomosaicImageURL: URL?

    public init(
        completedAt: Date = Date(),
        nutrients: [NutrientMetric] = [],
        costs: [CostEstimate] = [],
        totalCostFormatted: String = "Rp 0",
        allocationAreas: [FertilizerAreaPlan] = [],
        orthomosaicImageURL: URL? = nil
    ) {
        self.completedAt = completedAt
        self.nutrients = nutrients
        self.costs = costs
        self.totalCostFormatted = totalCostFormatted
        self.allocationAreas = allocationAreas
        self.orthomosaicImageURL = orthomosaicImageURL
    }
}

public struct NutrientMetric: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let current: Double
    public let target: Double

    public init(name: String, current: Double, target: Double) {
        self.name = name
        self.current = current
        self.target = target
    }
}

public struct CostEstimate: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let quantity: String
    public let cost: String

    public init(name: String, quantity: String, cost: String) {
        self.name = name
        self.quantity = quantity
        self.cost = cost
    }
}

public struct FertilizerAreaPlan: Identifiable, Sendable {
    public let id: String
    public let periods: [FertilizerPeriodPlan]

    public init(id: String, periods: [FertilizerPeriodPlan]) {
        self.id = id
        self.periods = periods
    }
}

public struct FertilizerPeriodPlan: Identifiable, Sendable {
    public var id: String { title }
    public let title: String
    public let dateRange: String
    public let lines: [FertilizerDoseLine]

    public init(title: String, dateRange: String, lines: [FertilizerDoseLine]) {
        self.title = title
        self.dateRange = dateRange
        self.lines = lines
    }
}

public struct FertilizerDoseLine: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let total: String
    public let dosage: String

    public init(name: String, total: String, dosage: String) {
        self.name = name
        self.total = total
        self.dosage = dosage
    }
}
