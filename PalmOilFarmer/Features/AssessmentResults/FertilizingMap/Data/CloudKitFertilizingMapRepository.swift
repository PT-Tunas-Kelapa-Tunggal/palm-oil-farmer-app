import CloudKit
import Foundation

actor CloudKitFertilizingMapRepository: FertilizingMapRepositoryProtocol {
    private let containerIdentifier: String
    private var selectedType: [String: ContractFertilizerType] = [:]
    private var doneState: [String: Bool] = [:]

    init(containerIdentifier: String) { self.containerIdentifier = containerIdentifier }

    func fetchMap(for gardenId: String) async throws -> FertilizingMapItem {
        try await makeMap(for: gardenId)
    }

    func selectFertilizer(fertilizerId: String, for gardenId: String) async throws -> FertilizingMapItem {
        if let type = ContractFertilizerType(rawValue: fertilizerId) { selectedType[gardenId] = type }
        return try await makeMap(for: gardenId)
    }

    func markAsFertilized(for gardenId: String, isDone: Bool) async throws -> FertilizingMapItem {
        guard let type = selectedType[gardenId] else { return try await makeMap(for: gardenId) }
        let database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
        let record = try await database.record(for: CKRecord.ID(recordName: gardenId))
        let reader = ScanRequestRecord(record)
        var schedule = try reader.fertilizationScheduling().get()
        var updated = false
        for period in schedule.indices where !updated {
            guard let step = schedule[period].fertilizers.firstIndex(where: {
                $0.fertilizerType == type || (Self.isNPK(type) && Self.isNPK($0.fertilizerType))
            }) else { continue }
            schedule[period].fertilizers[step].doneAt = isDone ? Date() : nil
            updated = true
        }
        guard updated else { throw CloudKitAssessmentDataError.missingField("jadwal untuk \(type.rawValue)") }
        _ = try await ScanRequestRecordWriter.saveFertilizationScheduling(schedule, on: record, to: database)
        doneState[gardenId] = isDone
        return try await makeMap(for: gardenId)
    }

    private func makeMap(for gardenId: String) async throws -> FertilizingMapItem {
        let database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
        let record = try await database.record(for: CKRecord.ID(recordName: gardenId))
        let reader = ScanRequestRecord(record)
        let needs = try reader.fertilizerNeedPerZone().get()
        guard !needs.isEmpty else { throw CloudKitAssessmentDataError.missingField("dosis pupuk per zona") }

        let farm = try await CloudKitFarmGreenIndexRepository(containerIdentifier: containerIdentifier)
            .fetchFarmGreenIndex(for: gardenId)
        guard let map = farm.orthomosaic else { throw CloudKitAssessmentDataError.missingField("peta kebun") }
        let schedule = reader.fertilizationScheduling().or([])
        let allTypes = Array(Set(needs.map(\.fertilizerType))).sorted { $0.rawValue < $1.rawValue }
        let savedNPK = await SavedNPKSelectionStore.shared.selection(for: gardenId)
        let savedNPKType = savedNPK.flatMap(ContractFertilizerType.init(rawValue:))
        let scheduledNPKType = schedule.flatMap(\.fertilizers)
            .map(\.fertilizerType).first(where: Self.isNPK)
        let chosenNPKType = [savedNPKType, scheduledNPKType, allTypes.first(where: Self.isNPK)]
            .compactMap { $0 }.first(where: allTypes.contains)
        let types = allTypes.filter { !Self.isNPK($0) || $0 == chosenNPKType }
        let type = selectedType[gardenId].flatMap { types.contains($0) ? $0 : nil } ?? types[0]
        selectedType[gardenId] = type
        let isDone = doneState[gardenId] ?? schedule
            .flatMap(\.fertilizers)
            .contains(where: {
                ($0.fertilizerType == type || (Self.isNPK(type) && Self.isNPK($0.fertilizerType)))
                    && $0.doneAt != nil
            })
        let options = types.map { optionType -> FertilizerPeriodOption in
            let matching = needs.filter { $0.fertilizerType == optionType }
            let amount = Self.totalAmount(matching, treeCount: farm.totalTrees)
            let division: AreaDivisionMode = matching.allSatisfy { $0.fertilizerApplicationType == .general } ? .wholeFarm : .perZona
            return FertilizerPeriodOption(id: optionType.rawValue, name: optionType.rawValue,
                timingSubtitle: "Dosis anjuran dari CloudKit", totalDose: Self.kg(amount),
                perTreeDose: Self.kg(farm.totalTrees > 0 ? amount / Double(farm.totalTrees) : amount),
                defaultDivision: division)
        }
        let option = options.first(where: { $0.id == type.rawValue }) ?? options[0]
        let selectedNeeds = needs.filter { $0.fertilizerType == type }
        let zoneDetails = map.zones.map { zone -> FertilizingZoneDetail in
            let zoneNeeds = selectedNeeds.filter { $0.fertilizerApplicationType == .zoneSpecific && $0.zoneId == zone.id }
            let generalNeeds = selectedNeeds.filter { $0.fertilizerApplicationType == .general }
            let zoneDose = Self.totalAmount(zoneNeeds, treeCount: Int(zone.treeCount))
            let wholeDose = Self.totalAmount(generalNeeds, treeCount: farm.totalTrees)
            let dose = zoneNeeds.isEmpty && farm.totalTrees > 0
                ? wholeDose * Double(zone.treeCount) / Double(farm.totalTrees)
                : zoneDose
            let xs = zone.boundingBox.map(\.x), ys = zone.boundingBox.map(\.y)
            return FertilizingZoneDetail(
                id: Int(zone.id), name: "Zona \(zone.id)", doseKg: dose,
                relativeX: CGFloat(((xs.min() ?? 0) + (xs.max() ?? 0)) / 2 / Double(max(map.imagePixelWidth, 1))),
                relativeY: CGFloat(((ys.min() ?? 0) + (ys.max() ?? 0)) / 2 / Double(max(map.imagePixelHeight, 1))),
                isFertilized: isDone
            )
        }
        return FertilizingMapItem(gardenId: gardenId, gardenName: farm.gardenName,
            selectedFertilizer: option, availableFertilizers: options, zones: zoneDetails,
            isMarkedDone: isDone, orthomosaic: map)
    }

    private static func totalAmount(_ needs: [FertilizerNeedItem], treeCount: Int) -> Double {
        needs.reduce(0) { value, need in
            let unit = need.dosageUnit.lowercased()
            let multiplier = unit.contains("pohon") || unit.contains("tree") ? Double(max(treeCount, 1)) : 1
            return value + max(0, need.recommendedDosage) * multiplier
        }
    }

    private static func isNPK(_ type: ContractFertilizerType) -> Bool {
        switch type {
        case .npk, .npk15_15_15, .npk12_6_22_3, .npk13_6_27_4, .npk13_8_27_4, .npk16_16_16:
            true
        default:
            false
        }
    }

    private static func kg(_ amount: Double) -> String {
        "\(amount.formatted(.number.precision(.fractionLength(0...1)))) kg"
    }
}
