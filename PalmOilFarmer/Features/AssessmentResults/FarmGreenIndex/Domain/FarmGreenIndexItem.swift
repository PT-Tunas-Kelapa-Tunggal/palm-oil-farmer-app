import Foundation

/// Area division presentation mode on the map ("Pembagian Area").
/// Sliced from Sketch: "Pemupukan / Peta Dosis Pupuk / Pembagian Area" -> "Area Picker"
public enum FarmAreaDivisionMode: String, CaseIterable, Identifiable, Equatable, Sendable {
    case perPohon = "Per Pohon"
    case perZona = "Per Zona"

    public var id: String { rawValue }
    public var title: String { rawValue }
}

/// Condition status level for oil palm trees in the farm greenness scan.
public enum TreeConditionCategory: String, CaseIterable, Identifiable, Equatable, Sendable {
    case normal = "Normal"
    case terindikasi = "Terindikasi"
    case defisiensi = "Defisiensi"
    case tidakWajar = "Tidak wajar"
    case unknown = "Belum diketahui"

    public var id: String { rawValue }

    public var title: String { rawValue }

    public var shortLegend: String {
        switch self {
        case .normal:
            return "Pertumbuhan pohon baik."
        case .terindikasi:
            return "Pertumbuhan mulai terganggu."
        case .defisiensi:
            return "Pertumbuhan terganggu sejak lama."
        case .tidakWajar:
            return "Berbeda dari sekitarnya."
        case .unknown:
            return "Label kondisi pohon belum tersedia."
        }
    }

    public var detailNarrative: String {
        switch self {
        case .normal:
            return "Pertumbuhan pohon baik dan serupa dengan pohon di sekitarnya."
        case .terindikasi:
            return "Pertumbuhan pohon mulai terganggu. Biasanya muncul di dekat pohon defisiensi dan bisa meluas ke pohon di sekitarnya."
        case .defisiensi:
            return "Pertumbuhan pohon sudah terganggu dalam waktu lama. Biasanya mengelompok dalam satu area."
        case .tidakWajar:
            return "Pohon ini berbeda jauh dari pohon di sekitarnya. Periksa langsung, bisa juga karena gangguan saat pemodelan."
        case .unknown:
            return "Kondisi pohon belum diklasifikasikan pada data hasil pemindaian."
        }
    }

    /// Color hex integer for the status badge / indicator dot.
    public var colorHex: UInt32 {
        switch self {
        case .normal:
            return 0x34C759 // #34C759 iOS Green
        case .terindikasi:
            return 0xC9C94A // #C9C94A Yellow / Chartreuse
        case .defisiensi:
            return 0xC2682B // #C2682B Amber / Rust
        case .tidakWajar:
            return 0x9C9CA1 // #9C9CA1 Slate Gray
        case .unknown:
            return 0x6B7280 // Neutral gray for unclassified trees
        }
    }
}

/// Summary item representing one condition category row in the legend & detail.
public struct TreeConditionSummaryItem: Identifiable, Equatable, Sendable {
    public var id: String { category.rawValue }
    public let category: TreeConditionCategory
    public let treeCount: Int
    public let percentageText: String

    public init(
        category: TreeConditionCategory,
        treeCount: Int,
        percentageText: String
    ) {
        self.category = category
        self.treeCount = treeCount
        self.percentageText = percentageText
    }
}

/// An interactive tree marker positioned on the farm satellite map.
public struct TreePinItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let treeNumber: String
    public let category: TreeConditionCategory
    public let coordinateX: Double // Relative 0.0 to 1.0 on map
    public let coordinateY: Double // Relative 0.0 to 1.0 on map

    public init(
        id: String,
        treeNumber: String,
        category: TreeConditionCategory,
        coordinateX: Double,
        coordinateY: Double
    ) {
        self.id = id
        self.treeNumber = treeNumber
        self.category = category
        self.coordinateX = coordinateX
        self.coordinateY = coordinateY
    }
}

public struct FarmMapCoordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// CloudKit analysis data positioned in the orthomosaic's pixel coordinate space.
public struct FarmOrthomosaicMapData: Equatable, Sendable {
    public let imageURL: URL?
    public let imagePixelWidth: Int
    public let imagePixelHeight: Int
    public let farmBoundary: [FarmMapCoordinate]
    public let zones: [FertilizingZoneItem]
    public let trees: [TreeIdentificationItem]

    public var zoneCount: Int {
        let zoneIDs = Set(zones.map(\.id))
        return zoneIDs.isEmpty ? Set(trees.map(\.zoneId)).count : zoneIDs.count
    }

    public init(
        imageURL: URL?,
        imagePixelWidth: Int,
        imagePixelHeight: Int,
        farmBoundary: [FarmMapCoordinate],
        zones: [FertilizingZoneItem],
        trees: [TreeIdentificationItem]
    ) {
        self.imageURL = imageURL
        self.imagePixelWidth = imagePixelWidth
        self.imagePixelHeight = imagePixelHeight
        self.farmBoundary = farmBoundary
        self.zones = zones
        self.trees = trees
    }
}

/// Domain entity representing the full Farm Green Index screen (Peta Kondisi Kebun).
public struct FarmGreenIndexItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let gardenName: String
    public let locationName: String
    public let mapImageName: String?
    public let totalTrees: Int
    public let treesToPayAttentionCount: Int
    public let categories: [TreeConditionSummaryItem]
    public let pins: [TreePinItem]
    public let orthomosaic: FarmOrthomosaicMapData?

    public init(
        id: String,
        gardenName: String,
        locationName: String,
        mapImageName: String? = "FarmGreenIndexMap",
        totalTrees: Int = 228,
        treesToPayAttentionCount: Int = 108,
        categories: [TreeConditionSummaryItem],
        pins: [TreePinItem] = [],
        orthomosaic: FarmOrthomosaicMapData? = nil
    ) {
        self.id = id
        self.gardenName = gardenName
        self.locationName = locationName
        self.mapImageName = mapImageName
        self.totalTrees = totalTrees
        self.treesToPayAttentionCount = treesToPayAttentionCount
        self.categories = categories
        self.pins = pins
        self.orthomosaic = orthomosaic
    }
}

// MARK: - Sample Fixture

extension FarmGreenIndexItem {
    /// Sample data matching Sketch artboards:
    /// - Hasil Peninjauan / Peta Kondisi Kebun / Collapsed
    /// - Hasil Peninjauan / Peta Kondisi Kebun / Legend
    /// - Hasil Peninjauan / Detail Kondisi / Normal
    /// - Hasil Peninjauan / Detail Kondisi / Terindikasi
    /// - Hasil Peninjauan / Detail Kondisi / Defisiensi
    /// - Hasil Peninjauan / Detail Kondisi / Tidak Wajar
    public static let sample = FarmGreenIndexItem(
        id: "farm-green-index-default",
        gardenName: "Belakang Rumah",
        locationName: "Malang Rapat, Bintan, Kep. Riau",
        mapImageName: "FarmGreenIndexMap",
        totalTrees: 228,
        treesToPayAttentionCount: 108,
        categories: [
            TreeConditionSummaryItem(
                category: .normal,
                treeCount: 120,
                percentageText: "53%"
            ),
            TreeConditionSummaryItem(
                category: .terindikasi,
                treeCount: 48,
                percentageText: "21%"
            ),
            TreeConditionSummaryItem(
                category: .defisiensi,
                treeCount: 59,
                percentageText: "26%"
            ),
            TreeConditionSummaryItem(
                category: .tidakWajar,
                treeCount: 1,
                percentageText: "<1%"
            )
        ],
        pins: [
            TreePinItem(id: "pin-1", treeNumber: "Pohon #42", category: .terindikasi, coordinateX: 0.42, coordinateY: 0.48),
            TreePinItem(id: "pin-2", treeNumber: "Pohon #108", category: .defisiensi, coordinateX: 0.58, coordinateY: 0.55),
            TreePinItem(id: "pin-3", treeNumber: "Pohon #12", category: .normal, coordinateX: 0.32, coordinateY: 0.38),
            TreePinItem(id: "pin-4", treeNumber: "Pohon #99", category: .tidakWajar, coordinateX: 0.65, coordinateY: 0.68)
        ]
    )
}
