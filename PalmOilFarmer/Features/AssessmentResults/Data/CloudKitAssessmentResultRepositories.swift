import CloudKit
import Foundation

enum CloudKitAssessmentDataError: LocalizedError {
    case invalidGardenID
    case missingField(String)

    var errorDescription: String? {
        switch self {
        case .invalidGardenID: "ID kebun tidak valid."
        case .missingField(let field): "Data CloudKit belum tersedia: \(field)."
        }
    }
}

private enum AssessmentRecordAccess {
    static func fetch(_ gardenID: String, containerIdentifier: String) async throws -> (CKDatabase, CKRecord, ScanRequestRecord) {
        guard !gardenID.isEmpty else { throw CloudKitAssessmentDataError.invalidGardenID }
        let database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
        let record = try await database.record(for: CKRecord.ID(recordName: gardenID))
        return (database, record, ScanRequestRecord(record))
    }
}

final class CloudKitNutrientConditionRepository: NutrientConditionRepositoryProtocol, @unchecked Sendable {
    private let containerIdentifier: String

    init(containerIdentifier: String) { self.containerIdentifier = containerIdentifier }

    func fetchNutrientCondition(for gardenId: String) async throws -> NutrientConditionOverview {
        let (_, _, reader) = try await AssessmentRecordAccess.fetch(gardenId, containerIdentifier: containerIdentifier)
        let comparisons: [FarmNutrientComparisonStatusItem]
        switch reader.farmNutrientComparisonStatus() {
        case .success(let decoded):
            comparisons = decoded
        case .failure(let error):
            if error.isMissing {
                throw CloudKitAssessmentDataError.missingField("perbandingan unsur hara")
            }
            throw error
        }
        guard !comparisons.isEmpty else { throw CloudKitAssessmentDataError.missingField("perbandingan unsur hara") }

        let definitions: [(ContractNutrientType, String, String)] = [
            (.nitrogen, "nitrogen", "N"),
            (.phosphorus, "fosfor", "P"),
            (.potassium, "kalium", "K"),
            (.magnesium, "magnesium", "Mg")
        ]
        let items = definitions.compactMap { type, id, symbol -> NutrientItem? in
            guard let comparison = comparisons.first(where: { $0.nutrientType == type }) else { return nil }
            let name = type.rawValue
            let currentValue = Int(comparison.current.rounded())
            let requiredValue = Int(comparison.recommendation.rounded())
            let status: NutrientStatus = currentValue < requiredValue ? .deficient : currentValue > requiredValue ? .excess : .sufficient
            let verdict: String
            switch status {
            case .deficient: verdict = "Pasokan \(name.lowercased()) saat ini di bawah anjuran."
            case .excess: verdict = "Pasokan \(name.lowercased()) saat ini melebihi anjuran."
            case .sufficient: verdict = "Pasokan \(name.lowercased()) saat ini sesuai anjuran."
            }
            return NutrientItem(
                id: id, name: name, symbol: symbol, title: "\(name) (\(symbol))",
                sourceDescription: "Hasil peninjauan drone", status: status,
                description: "Perbandingan pasokan dan kebutuhan per hektare dalam satu tahun.",
                comparison: NutrientComparison(currentPracticeValue: currentValue, requiredValue: requiredValue, unit: "kg/ha/tahun"),
                verdict: verdict,
                warningImpact: status == .sufficient ? nil : "Tinjau kembali dosis pupuk bersama petugas kebun."
            )
        }
        guard !items.isEmpty else { throw CloudKitAssessmentDataError.missingField("perbandingan unsur hara") }
        let low = items.filter { $0.status == .deficient }.count
        let high = items.filter { $0.status == .excess }.count
        return NutrientConditionOverview(
            id: gardenId,
            title: "Kondisi Hara",
            subtitle: "\(low) unsur kurang dan \(high) unsur berlebih per hektare per tahun.",
            nutrients: items
        )
    }
}

final class CloudKitFertilizerEstimationRepository: FertilizerEstimationRepositoryProtocol, @unchecked Sendable {
    private let containerIdentifier: String
    private let lock = NSLock()
    private var selectedNPKByGarden: [String: String] = [:]

    init(containerIdentifier: String) { self.containerIdentifier = containerIdentifier }

    func fetchEstimation(for gardenId: String) async throws -> FertilizerEstimationOverview {
        let (_, _, reader) = try await AssessmentRecordAccess.fetch(gardenId, containerIdentifier: containerIdentifier)
        let needs = try reader.fertilizerNeedPerZone().get()
        guard !needs.isEmpty else { throw CloudKitAssessmentDataError.missingField("kebutuhan pupuk") }

        let treeCount = max(reader.treeIdentification().or([]).count, 1)
        let groups = Dictionary(grouping: needs, by: \.fertilizerType)
        let npkTypes = groups.keys.filter(Self.isNPK).sorted { $0.rawValue < $1.rawValue }
        let options = npkTypes.map { type in
            Self.npkOption(type: type, doseKg: Self.amount(groups[type] ?? [], treeCount: treeCount))
        }
        let defaultID = options.min { $0.totalPrice < $1.totalPrice }?.id ?? ""
        let savedID = await SavedNPKSelectionStore.shared.selection(for: gardenId)
        let selectedID = lock.withLock { selectedNPKByGarden[gardenId] } ?? savedID ?? defaultID
        let selected = options.first(where: { $0.id == selectedID }) ?? options.first

        var products = groups.keys.filter { !Self.isNPK($0) }.sorted { $0.rawValue < $1.rawValue }.compactMap { type -> FertilizerItem? in
            let dose = Self.amount(groups[type] ?? [], treeCount: treeCount)
            guard dose > 0 else { return nil }
            let bags = max(Int(ceil(dose / 50)), 1)
            return Self.productRow(id: type.rawValue, name: type.rawValue, doseKg: dose, bagCount: bags, price: Self.price(for: type))
        }
        if let selected {
            products.append(Self.productRow(
                id: "npk", name: selected.name, doseKg: Double(selected.weightKg),
                bagCount: selected.bagCount, price: selected.pricePerBag, customizable: true
            ))
        }
        products.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let budgetPerHectare = reader.fertilizationBudgetPerHa().or(0)
        let budget = Int((reader.farmSize().or(0) * Double(max(budgetPerHectare, 0))).rounded())
        let selectedIDValue = selected?.id ?? ""
        products = products.map { product in
            guard product.isCustomizableNPK, let selected else { return product }
            let least = options.map(\.totalPrice).min() ?? selected.totalPrice
            let saving = selected.totalPrice - least
            return Self.productRow(
                id: product.id, name: selected.name, doseKg: Double(selected.weightKg), bagCount: selected.bagCount,
                price: selected.pricePerBag, customizable: true,
                savingsHint: saving > 0 ? "Ada pilihan NPK yang \(CurrencyFormatter.formatRupiah(saving)) lebih hemat." : nil
            )
        }
        return FertilizerEstimationOverview(
            id: gardenId,
            gardenName: reader.farmName().or("Kebun"),
            periodDescription: "untuk kebutuhan 1 tahun",
            budgetLimit: budget,
            fertilizers: products,
            npkOptions: options,
            selectedNPKId: selectedIDValue,
            defaultNPKId: defaultID,
            footnote: "Jumlah pupuk berasal dari kebutuhan CloudKit. Harga per sak 50 kg merupakan estimasi lokal."
        )
    }

    func selectNPK(optionId: String, for gardenId: String) async throws -> FertilizerEstimationOverview {
        lock.withLock { selectedNPKByGarden[gardenId] = optionId }
        return try await fetchEstimation(for: gardenId)
    }
    
    func saveNPK(optionId: String, for gardenId: String) async throws {
        let estimation = try await fetchEstimation(for: gardenId)
        guard estimation.npkOptions.contains(where: { $0.id == optionId }) else {
            throw CloudKitAssessmentDataError.missingField("pilihan NPK")
        }
        await SavedNPKSelectionStore.shared.save(optionId, for: gardenId)
    }

    private static func amount(_ needs: [FertilizerNeedItem], treeCount: Int) -> Double {
        needs.reduce(0) { sum, need in
            let unit = need.dosageUnit.lowercased()
            let multiplier = unit.contains("pohon") || unit.contains("tree") ? Double(treeCount) : 1
            return sum + max(0, need.recommendedDosagePerZonePerYear) * multiplier
        }
    }

    private static func isNPK(_ type: ContractFertilizerType) -> Bool {
        [.npk, .npk15_15_15, .npk12_6_22_3, .npk13_6_27_4, .npk13_8_27_4, .npk16_16_16].contains(type)
    }

    private static func price(for type: ContractFertilizerType) -> Int {
        switch type {
        case .dolomite: 100_000
        case .urea: 500_000
        case .npk12_6_22_3: 630_000
        case .npk13_6_27_4, .npk13_8_27_4: 550_000
        case .npk16_16_16: 890_000
        case .npk, .npk15_15_15: 740_000
        default: 0
        }
    }

    private static func npkOption(type: ContractFertilizerType, doseKg: Double) -> NPKOption {
        let bags = max(Int(ceil(max(doseKg, 0) / 50)), 1)
        let price = price(for: type)
        let isCheapest = type == .npk13_6_27_4 || type == .npk13_8_27_4
        return NPKOption(
            id: type.rawValue,
            name: displayName(for: type),
            weightKg: Int(doseKg.rounded()),
            bagCount: bags,
            pricePerBag: price,
            totalPrice: bags * price,
            tag: isCheapest ? "Paling hemat" : nil
        )
    }

    private static func displayName(for type: ContractFertilizerType) -> String {
        switch type {
        case .npk: "NPK"
        case .npk15_15_15: "NPK 15-15-15"
        case .npk12_6_22_3: "NPK 12-6-22-3"
        case .npk13_6_27_4: "NPK 13-6-27-4"
        case .npk13_8_27_4: "NPK 13-8-27-4"
        case .npk16_16_16: "NPK 16-16-16"
        default: type.rawValue
        }
    }

    private static func productRow(id: String, name: String, doseKg: Double, bagCount: Int, price: Int,
                                   customizable: Bool = false, savingsHint: String? = nil) -> FertilizerItem {
        FertilizerItem(id: id, name: name, pricePerBag: price, bagWeightKg: 50,
                       weightKg: Int(doseKg.rounded()), bagCount: bagCount, totalPrice: bagCount * price,
                       isCustomizableNPK: customizable, savingsHint: savingsHint)
    }
}

final class CloudKitResultOverviewRepository: ResultOverviewRepositoryProtocol, @unchecked Sendable {
    private let containerIdentifier: String
    private let scheduleRepository: CloudKitFertilizerScheduleRepository
    private let nutrientRepository: CloudKitNutrientConditionRepository
    private let estimationRepository: CloudKitFertilizerEstimationRepository

    init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        scheduleRepository = CloudKitFertilizerScheduleRepository(containerIdentifier: containerIdentifier)
        nutrientRepository = CloudKitNutrientConditionRepository(containerIdentifier: containerIdentifier)
        estimationRepository = CloudKitFertilizerEstimationRepository(containerIdentifier: containerIdentifier)
    }

    func fetchOverview(for gardenId: String) async throws -> ResultOverviewItem {
        let (_, _, reader) = try await AssessmentRecordAccess.fetch(gardenId, containerIdentifier: containerIdentifier)
        guard let gardenUUID = UUID(uuidString: gardenId) else { throw CloudKitAssessmentDataError.invalidGardenID }
        let schedule = try await scheduleRepository.fetchSchedule(gardenID: gardenUUID)
        let nutrient = try await nutrientRepository.fetchNutrientCondition(for: gardenId)
        let estimation = try await estimationRepository.fetchEstimation(for: gardenId)
        let month = DateFormatter()
        month.locale = Locale(identifier: "id_ID")
        month.dateFormat = "MMM"
        let periods = schedule.periods.map { period in
            FertilizerPeriodItem(id: "period-\(period.sequence)", orderText: Self.ordinal(period.sequence),
                                 month: month.string(from: period.startDate),
                                 year: String(Calendar(identifier: .gregorian).component(.year, from: period.startDate)))
        }
        let low = nutrient.nutrients.filter { $0.status == .deficient }.count
        let high = nutrient.nutrients.filter { $0.status == .excess }.count
        let nutrientItems = nutrient.nutrients.map { item in
            NutrientStatusSummaryItem(symbol: item.symbol, name: item.name,
                status: item.status == .deficient ? .kurang : item.status == .excess ? .berlebih : .cukup)
        }
        return ResultOverviewItem(
            id: gardenId, gardenName: reader.farmName().or("Kebun"), locationName: reader.farmAddress().or(""),
            recommendationSubtitle: "\(periods.count) kali pemupukan berdasarkan jadwal tersimpan", periods: periods,
            nutrientStatusTitle: low == 0 && high == 0 ? "Seimbang" : "Belum Seimbang",
            nutrientStatusSummary: "Hasil dari praktik pemupukan Anda sebelumnya: \(low) hara kurang dan \(high) berlebih",
            nutrients: nutrientItems,
            greenness: FarmGreennessSummary(affectedTreeCount: 0, totalTreeCount: 0, statusDescription: "hasil pemantauan drone"),
            fertilizerEstimation: FertilizerEstimationSummary(totalCost: estimation.totalCost,
                fertilizerTypeCount: estimation.fertilizers.count, budgetLimit: estimation.budgetLimit),
            gardenDataRows: [
                GardenDataSummaryRowItem(id: "identity", title: "Identitas Kebun", subtitle: "Lokasi, luas, tahun tanam, jenis tanah", iconSystemName: "square.dashed.inset.filled", isLocked: false),
                GardenDataSummaryRowItem(id: "history", title: "Riwayat Panen dan Pemupukan", subtitle: "Dasar perhitungan kondisi hara", iconSystemName: "doc.text", isLocked: false)
            ]
        )
    }

    private static func ordinal(_ value: Int) -> String {
        switch value { case 1: "Pertama"; case 2: "Kedua"; case 3: "Ketiga"; default: "Ke-\(value)" }
    }
}
