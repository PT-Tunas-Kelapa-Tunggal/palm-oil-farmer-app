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
        let predictions = try reader.fertilizerCostPredictions().get()
        let savedID = await SavedNPKSelectionStore.shared.selection(for: gardenId)
        let budgetPerHectare = reader.fertilizationBudgetPerHa().or(0)
        let budget = Int((reader.farmSize().or(0) * Double(max(budgetPerHectare, 0))).rounded())
        return try Self.makeOverview(
            gardenId: gardenId, gardenName: reader.farmName().or("Kebun"), budget: budget,
            predictions: predictions,
            selectedID: lock.withLock { selectedNPKByGarden[gardenId] } ?? savedID
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

    private static func isNPK(_ type: ContractFertilizerType) -> Bool {
        [.npk, .npk15_15_15, .npk12_6_22_3, .npk13_6_27_4, .npk13_8_27_4, .npk16_16_16].contains(type)
    }

    private struct PredictionValues {
        let weightKg: Int
        let bagCount: Int
        let bagWeightKg: Int
        let pricePerBag: Int
        let totalCost: Int
    }

    static func makeOverview(
        gardenId: String, gardenName: String, budget: Int,
        predictions: FertilizerCostPredictions, selectedID: String?
    ) throws -> FertilizerEstimationOverview {
        guard !predictions.byFertilizer.isEmpty else {
            throw CloudKitAssessmentDataError.missingField("perkiraan biaya pupuk")
        }
        let entries = try predictions.byFertilizer.keys.sorted { $0.rawValue < $1.rawValue }
            .compactMap { type -> (ContractFertilizerType, PredictionValues)? in
                guard let prediction = predictions.byFertilizer[type],
                      let values = try predictionValues(prediction, for: type) else { return nil }
                return (type, values)
            }
        let npkEntries = entries.filter { isNPK($0.0) }
        let lowestNPKCost = npkEntries.map { $0.1.totalCost }.min()
        let options = npkEntries.map { type, values in
            NPKOption(
                id: type.rawValue, name: displayName(for: type), weightKg: values.weightKg,
                bagCount: values.bagCount, pricePerBag: values.pricePerBag,
                totalPrice: values.totalCost,
                tag: values.totalCost == lowestNPKCost ? "Paling hemat" : nil
            )
        }
        let defaultID = options.first(where: { $0.totalPrice == lowestNPKCost })?.id ?? ""
        let selected = options.first(where: { $0.id == selectedID }) ?? options.first(where: { $0.id == defaultID })
        var products = entries.filter { !isNPK($0.0) }.map { type, values in
            productRow(id: type.rawValue, name: type.rawValue, values: values)
        }
        if let selected, let values = npkEntries.first(where: { $0.0.rawValue == selected.id })?.1 {
            let saving = selected.totalPrice - (lowestNPKCost ?? selected.totalPrice)
            products.append(productRow(
                id: "npk", name: selected.name, values: values, customizable: true,
                savingsHint: saving > 0
                    ? "Ada pilihan NPK yang \(CurrencyFormatter.formatRupiah(saving)) lebih hemat." : nil
            ))
        }
        products.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return FertilizerEstimationOverview(
            id: gardenId, gardenName: gardenName, periodDescription: "untuk kebutuhan 1 tahun",
            budgetLimit: budget, fertilizers: products, npkOptions: options,
            selectedNPKId: selected?.id ?? "", defaultNPKId: defaultID,
            footnote: "Berat, jumlah sak, dan total harga mengikuti hasil peninjauan kebun. Harga per sak dihitung dari total harga dibagi jumlah sak."
        )
    }

    private static func predictionValues(
        _ prediction: FertilizerCostPredictionItem, for type: ContractFertilizerType
    ) throws -> PredictionValues? {
        guard let kilograms = prediction.totalKg, let cost = prediction.totalCost,
              kilograms.isFinite, cost.isFinite,
              kilograms >= 0, cost >= 0,
              kilograms < Double(Int.max), cost < Double(Int.max),
              prediction.totalBagsNeeded >= 0 else {
            throw CloudKitAssessmentDataError.missingField("perkiraan biaya \(type.rawValue)")
        }
        let bags = prediction.totalBagsNeeded
        if kilograms == 0 && bags == 0 && cost == 0 { return nil }
        guard bags > 0 else {
            throw CloudKitAssessmentDataError.missingField("jumlah sak \(type.rawValue)")
        }
        return PredictionValues(
            weightKg: Int(kilograms.rounded()), bagCount: bags,
            bagWeightKg: Int((kilograms / Double(bags)).rounded()),
            pricePerBag: Int((cost / Double(bags)).rounded()), totalCost: Int(cost.rounded())
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

    private static func productRow(id: String, name: String, values: PredictionValues,
                                   customizable: Bool = false, savingsHint: String? = nil) -> FertilizerItem {
        FertilizerItem(id: id, name: name, pricePerBag: values.pricePerBag, bagWeightKg: values.bagWeightKg,
                       weightKg: values.weightKg, bagCount: values.bagCount, totalPrice: values.totalCost,
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
