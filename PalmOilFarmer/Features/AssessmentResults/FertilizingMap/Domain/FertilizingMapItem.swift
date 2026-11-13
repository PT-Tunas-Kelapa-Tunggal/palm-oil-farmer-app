import Foundation
import CoreGraphics

public enum AreaDivisionMode: String, CaseIterable, Identifiable, Sendable {
    case perZona = "Per Zona"
    case perPohon = "Per Pohon"
    case wholeFarm = "Seluruh Kebun"

    public var id: String { rawValue }
    public var title: String { rawValue }
}

public struct FertilizerPeriodOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let timingSubtitle: String
    public let totalDose: String
    public let perTreeDose: String
    public let defaultDivision: AreaDivisionMode

    public init(
        id: String,
        name: String,
        timingSubtitle: String,
        totalDose: String,
        perTreeDose: String = "3,5 kg",
        defaultDivision: AreaDivisionMode = .perZona
    ) {
        self.id = id
        self.name = name
        self.timingSubtitle = timingSubtitle
        self.totalDose = totalDose
        self.perTreeDose = perTreeDose
        self.defaultDivision = defaultDivision
    }
}

public struct FertilizerTypeOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let unit: String

    public init(id: String, name: String, unit: String = "kg") {
        self.id = id
        self.name = name
        self.unit = unit
    }
}

public struct FertilizingZoneDetail: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let doseKg: Double
    /// Relative coordinate (0.0 ... 1.0) on the map canvas
    public let relativeX: CGFloat
    public let relativeY: CGFloat
    public var isFertilized: Bool

    public init(
        id: Int,
        name: String,
        doseKg: Double,
        relativeX: CGFloat,
        relativeY: CGFloat,
        isFertilized: Bool = false
    ) {
        self.id = id
        self.name = name
        self.doseKg = doseKg
        self.relativeX = relativeX
        self.relativeY = relativeY
        self.isFertilized = isFertilized
    }
}

public struct FertilizingMapItem: Sendable {
    public let id: UUID
    public let gardenId: String
    public let gardenName: String
    public var selectedFertilizer: FertilizerPeriodOption
    public let availableFertilizers: [FertilizerPeriodOption]
    public var zones: [FertilizingZoneDetail]
    public var isMarkedDone: Bool
    public let orthomosaic: FarmOrthomosaicMapData?

    public var totalDoseKg: Double {
        zones.reduce(0) { $0 + $1.doseKg }
    }

    public var totalZoneCount: Int {
        zones.count
    }

    public init(
        id: UUID = UUID(),
        gardenId: String,
        gardenName: String,
        selectedFertilizer: FertilizerPeriodOption,
        availableFertilizers: [FertilizerPeriodOption],
        zones: [FertilizingZoneDetail],
        isMarkedDone: Bool = false,
        orthomosaic: FarmOrthomosaicMapData? = nil
    ) {
        self.id = id
        self.gardenId = gardenId
        self.gardenName = gardenName
        self.selectedFertilizer = selectedFertilizer
        self.availableFertilizers = availableFertilizers
        self.zones = zones
        self.isMarkedDone = isMarkedDone
        self.orthomosaic = orthomosaic
    }

    public var gardenUUID: UUID? {
        UUID(uuidString: gardenId)
    }
}

public extension UUID {
    static func == (lhs: UUID, rhs: String) -> Bool {
        lhs.uuidString.caseInsensitiveCompare(rhs) == .orderedSame
    }

    static func == (lhs: String, rhs: UUID) -> Bool {
        lhs.caseInsensitiveCompare(rhs.uuidString) == .orderedSame
    }
}

