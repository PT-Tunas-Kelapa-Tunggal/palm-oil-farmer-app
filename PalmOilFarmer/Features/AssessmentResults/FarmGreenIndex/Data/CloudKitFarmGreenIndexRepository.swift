import CloudKit
import Foundation
import ImageIO

/// Reads the completed scan payload and its orthomosaic from the garden's CloudKit record.
public final class CloudKitFarmGreenIndexRepository: FarmGreenIndexRepositoryProtocol, @unchecked Sendable {
    private let database: CKDatabase
    private let fileManager = FileManager.default
    private let loadsOrthomosaicImage: Bool

    public init(containerIdentifier: String, loadsOrthomosaicImage: Bool = true) {
        database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
        self.loadsOrthomosaicImage = loadsOrthomosaicImage
    }

    public func fetchFarmGreenIndex(for gardenId: String) async throws -> FarmGreenIndexItem {
        let recordID = CKRecord.ID(recordName: gardenId)
        let record = try await database.record(for: recordID)
        let reader = ScanRequestRecord(record)

        let trees = reader.treeIdentification().or([])
        let zones = reader.fertilizingZone().or([])
        let boundary = reader.farmBoundary().or([]).map {
            FarmMapCoordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }
        let imageURL = loadsOrthomosaicImage
            ? cachedOrthomosaicURL(from: reader.orthomosaicImage().orNil?.fileURL, record: record)
            : nil
        let imageSize = imageURL.flatMap(Self.pixelSize(of:)) ?? .zero
        let mapData = FarmOrthomosaicMapData(
            imageURL: imageURL,
            imagePixelWidth: Int(imageSize.width),
            imagePixelHeight: Int(imageSize.height),
            farmBoundary: boundary,
            zones: zones,
            trees: trees
        )

        let pins = trees.compactMap { tree -> TreePinItem? in
            guard let center = Self.center(of: tree.boundingBox),
                  imageSize.width > 0, imageSize.height > 0 else { return nil }
            return TreePinItem(
                id: "tree-\(tree.id)",
                treeNumber: "Pohon #\(tree.id)",
                category: Self.category(for: tree.healthynessLabel),
                coordinateX: center.x / imageSize.width,
                coordinateY: center.y / imageSize.height
            )
        }

        let totalTrees = trees.count
        let categories = TreeConditionCategory.allCases.map { category in
            let count = trees.filter { Self.category(for: $0.healthynessLabel) == category }.count
            let percentage = totalTrees == 0 ? 0 : Int((Double(count) / Double(totalTrees) * 100).rounded())
            return TreeConditionSummaryItem(
                category: category,
                treeCount: count,
                percentageText: "\(percentage)%"
            )
        }

        let treesToPayAttention = trees.filter {
            switch Self.category(for: $0.healthynessLabel) {
            case .normal, .unknown: false
            case .terindikasi, .defisiensi, .tidakWajar: true
            }
        }.count

        return FarmGreenIndexItem(
            id: gardenId,
            gardenName: reader.farmName().or("Kebun"),
            locationName: reader.farmAddress().or(""),
            mapImageName: nil,
            totalTrees: totalTrees,
            treesToPayAttentionCount: treesToPayAttention,
            categories: categories,
            pins: pins,
            orthomosaic: mapData
        )
    }

    private func cachedOrthomosaicURL(from sourceURL: URL?, record: CKRecord) -> URL? {
        guard let sourceURL else { return nil }
        do {
            let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appending(path: "PalmOilFarmer/Orthomosaics", directoryHint: .isDirectory)
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

            let revision = Int(record.modificationDate?.timeIntervalSince1970 ?? 0)
            let fileExtension = sourceURL.pathExtension.isEmpty ? "image" : sourceURL.pathExtension
            let destination = cacheDirectory.appending(path: "\(record.recordID.recordName)-\(revision).\(fileExtension)")
            if !fileManager.fileExists(atPath: destination.path) {
                try fileManager.copyItem(at: sourceURL, to: destination)
            }
            return destination
        } catch {
            return nil
        }
    }

    private static func pixelSize(of url: URL) -> CGSize? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return CGSize(width: width, height: height)
    }

    private static func center(of points: [PixelPoint]) -> CGPoint? {
        guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return nil }
        return CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
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
}
