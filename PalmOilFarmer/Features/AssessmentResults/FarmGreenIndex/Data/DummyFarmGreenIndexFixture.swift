import Foundation
import UIKit

/// Builds the local map fixture from the supplied tree and zone analysis JSON.
@MainActor
enum DummyFarmGreenIndexFixture {
    private static let northLatitude = 1.1536
    private static let southLatitude = 1.1524
    private static let westLongitude = 104.574297
    private static let eastLongitude = 104.575703

    static func makeItem() -> FarmGreenIndexItem {
        let imageURL = cachedOrthomosaicURL()
        let image = UIImage(named: "DummyOrthomosaic")?.cgImage
        let fixture = loadAnalysis()
        let imageWidth = fixture?.metadata.imageWidthPx ?? image?.width ?? 1_950
        let imageHeight = fixture?.metadata.imageHeightPx ?? image?.height ?? 1_664
        let zones = fixture?.zones.map { zone in
            FertilizingZoneItem(
                id: zone.id,
                treeCount: Int64(zone.treeCount),
                boundingBox: pixelPolygon(for: zone.boundingBox)
            )
        } ?? []

        let rawTrees = fixture?.zones.flatMap { zone in
            zone.trees.map { (tree: $0, zoneID: zone.id) }
        } ?? []
        let thresholds = quartileThresholds(for: rawTrees.map { $0.tree.vari.meanVari })
        let trees = rawTrees.map { entry in
            TreeIdentificationItem(
                id: entry.tree.id,
                boundingBox: pixelPolygon(for: entry.tree.boundingBox),
                zoneId: entry.zoneID,
                healthynessLabel: healthLabel(for: entry.tree.vari.meanVari, thresholds: thresholds)
            )
        }
        let pins = rawTrees.map { entry in
            let box = entry.tree.boundingBox
            let category = Self.category(for: healthLabel(for: entry.tree.vari.meanVari, thresholds: thresholds))
            return TreePinItem(
                id: "tree-\(entry.tree.id)",
                treeNumber: "Pohon #\(entry.tree.id)",
                category: category,
                coordinateX: ((box.x1 + box.x2) / 2) / Double(imageWidth),
                coordinateY: ((box.y1 + box.y2) / 2) / Double(imageHeight)
            )
        }

        let categories = TreeConditionCategory.allCases.map { category in
            let count = trees.filter { Self.category(for: $0.healthynessLabel) == category }.count
            let percent = trees.isEmpty ? 0 : Int((Double(count) / Double(trees.count) * 100).rounded())
            return TreeConditionSummaryItem(category: category, treeCount: count, percentageText: "\(percent)%")
        }
        let needsAttention = trees.filter {
            switch Self.category(for: $0.healthynessLabel) {
            case .normal, .unknown: false
            case .terindikasi, .defisiensi, .tidakWajar: true
            }
        }.count

        return FarmGreenIndexItem(
            id: "dummy-farm-green-index",
            gardenName: "Kebun Contoh",
            locationName: "Malang Rapat, Bintan, Kep. Riau",
            mapImageName: nil,
            totalTrees: trees.count,
            treesToPayAttentionCount: needsAttention,
            categories: categories,
            pins: pins,
            orthomosaic: FarmOrthomosaicMapData(
                imageURL: imageURL,
                imagePixelWidth: imageWidth,
                imagePixelHeight: imageHeight,
                farmBoundary: sampleBoundary,
                zones: zones,
                trees: trees
            )
        )
    }

    private static var sampleBoundary: [FarmMapCoordinate] {
        [
            coordinate(x: 0.08, y: 0.20), coordinate(x: 0.16, y: 0.13),
            coordinate(x: 0.84, y: 0), coordinate(x: 0.96, y: 0.08),
            coordinate(x: 0.99, y: 0.78), coordinate(x: 0.93, y: 0.91),
            coordinate(x: 0.70, y: 0.98), coordinate(x: 0.32, y: 1),
            coordinate(x: 0.15, y: 0.94), coordinate(x: 0.03, y: 0.76),
            coordinate(x: 0, y: 0.28)
        ]
    }

    private static func coordinate(x: Double, y: Double) -> FarmMapCoordinate {
        FarmMapCoordinate(
            latitude: northLatitude - (northLatitude - southLatitude) * y,
            longitude: westLongitude + (eastLongitude - westLongitude) * x
        )
    }

    private static func pixelPolygon(for box: FixtureBoundingBox) -> [PixelPoint] {
        [
            PixelPoint(x: box.x1, y: box.y1),
            PixelPoint(x: box.x2, y: box.y1),
            PixelPoint(x: box.x2, y: box.y2),
            PixelPoint(x: box.x1, y: box.y2)
        ]
    }

    private static func quartileThresholds(for values: [Double]) -> (lower: Double, median: Double, upper: Double) {
        guard !values.isEmpty else { return (0, 0, 0) }
        let sorted = values.sorted()
        return (quantile(sorted, probability: 0.25), quantile(sorted, probability: 0.5), quantile(sorted, probability: 0.75))
    }

    private static func quantile(_ sorted: [Double], probability: Double) -> Double {
        let position = probability * Double(sorted.count - 1)
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = Int(position.rounded(.up))
        let fraction = position - Double(lowerIndex)
        return sorted[lowerIndex] * (1 - fraction) + sorted[upperIndex] * fraction
    }

    private static func healthLabel(
        for meanVari: Double,
        thresholds: (lower: Double, median: Double, upper: Double)
    ) -> TreeHealthLabel {
        if meanVari >= thresholds.upper { .normal }
        else if meanVari >= thresholds.median { .terindikasi }
        else if meanVari >= thresholds.lower { .defisiensi }
        else { .tidakWajar }
    }

    private static func category(for label: TreeHealthLabel) -> TreeConditionCategory {
        switch label {
        case .normal: .normal
        case .terindikasi: .terindikasi
        case .defisiensi: .defisiensi
        case .tidakWajar: .tidakWajar
        case .unknown: .unknown
        }
    }

    private static func loadAnalysis() -> ZoneAnalysisFixture? {
        guard let url = Bundle.main.url(forResource: "oil_palm_zones_vari", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ZoneAnalysisFixture.self, from: data)
    }

    private static func cachedOrthomosaicURL() -> URL? {
        guard let image = UIImage(named: "DummyOrthomosaic"), let pngData = image.pngData() else { return nil }
        do {
            let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appending(path: "PalmOilFarmer/Orthomosaics", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appending(path: "dummy-vari-quartile-orthomosaic.png")
            try pngData.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

private struct ZoneAnalysisFixture: Decodable {
    let metadata: FixtureMetadata
    let zones: [FixtureZone]
}

private struct FixtureMetadata: Decodable {
    let imageWidthPx: Int
    let imageHeightPx: Int

    enum CodingKeys: String, CodingKey {
        case imageWidthPx = "image_width_px"
        case imageHeightPx = "image_height_px"
    }
}

private struct FixtureZone: Decodable {
    let id: Int64
    let treeCount: Int
    let boundingBox: FixtureBoundingBox
    let trees: [FixtureTree]

    enum CodingKeys: String, CodingKey {
        case id = "zone_id"
        case treeCount = "tree_count"
        case boundingBox = "bbox"
        case trees
    }
}

private struct FixtureTree: Decodable {
    let id: Int64
    let boundingBox: FixtureBoundingBox
    let vari: FixtureVari

    enum CodingKeys: String, CodingKey {
        case id = "tree_id"
        case boundingBox = "bbox"
        case vari
    }
}

private struct FixtureBoundingBox: Decodable {
    let x1: Double
    let y1: Double
    let x2: Double
    let y2: Double
}

private struct FixtureVari: Decodable {
    let meanVari: Double

    enum CodingKeys: String, CodingKey {
        case meanVari = "mean_vari"
    }
}
