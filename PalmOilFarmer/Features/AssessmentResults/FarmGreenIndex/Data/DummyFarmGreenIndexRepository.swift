import Foundation

/// Local repository used until the farm scan and orthomosaic are available in CloudKit.
public actor DummyFarmGreenIndexRepository: FarmGreenIndexRepositoryProtocol {
    private let item: FarmGreenIndexItem?
    private let cloudKitRepository: (any FarmGreenIndexRepositoryProtocol)?

    public init(
        item: FarmGreenIndexItem? = nil,
        cloudKitRepository: (any FarmGreenIndexRepositoryProtocol)? = nil
    ) {
        self.item = item
        self.cloudKitRepository = cloudKitRepository
    }

    public func fetchFarmGreenIndex(for gardenId: String) async throws -> FarmGreenIndexItem {
        if let item { return item }
        let dummy = await DummyFarmGreenIndexFixture.makeItem()
        guard let cloudKitRepository else { return dummy }

        do {
            let cloudItem = try await cloudKitRepository.fetchFarmGreenIndex(for: gardenId)
            return Self.combine(cloudItem: cloudItem, dummyItem: dummy)
        } catch {
            // Keep the screen usable while CloudKit has no matching completed scan record.
            return dummy
        }
    }

    private static func combine(cloudItem: FarmGreenIndexItem, dummyItem: FarmGreenIndexItem) -> FarmGreenIndexItem {
        guard let dummyMap = dummyItem.orthomosaic else { return cloudItem }
        let cloudMap = cloudItem.orthomosaic
        // The selected JSON fixture is the source for tree/zone geometry so its
        // pixel boxes remain aligned with the bundled quartile image.
        let trees = dummyMap.trees
        let zones = dummyMap.zones
        let cloudBoundary = cloudMap?.farmBoundary ?? []
        let boundary = cloudBoundary.count >= 3 ? cloudBoundary : dummyMap.farmBoundary

        let pins = trees.compactMap { tree -> TreePinItem? in
            guard let center = Self.center(of: tree.boundingBox),
                  dummyMap.imagePixelWidth > 0, dummyMap.imagePixelHeight > 0 else { return nil }
            return TreePinItem(
                id: "tree-\(tree.id)",
                treeNumber: "Pohon #\(tree.id)",
                category: Self.category(for: tree.healthynessLabel),
                coordinateX: center.x / Double(dummyMap.imagePixelWidth),
                coordinateY: center.y / Double(dummyMap.imagePixelHeight)
            )
        }
        let categories = TreeConditionCategory.allCases.map { category in
            let count = trees.filter { Self.category(for: $0.healthynessLabel) == category }.count
            let percentage = trees.isEmpty ? 0 : Int((Double(count) / Double(trees.count) * 100).rounded())
            return TreeConditionSummaryItem(
                category: category,
                treeCount: count,
                percentageText: "\(percentage)%"
            )
        }
        let needsAttention = trees.filter {
            switch Self.category(for: $0.healthynessLabel) {
            case .normal, .unknown: false
            case .terindikasi, .defisiensi, .tidakWajar: true
            }
        }.count

        return FarmGreenIndexItem(
            id: cloudItem.id,
            gardenName: cloudItem.gardenName.isEmpty ? dummyItem.gardenName : cloudItem.gardenName,
            locationName: cloudItem.locationName.isEmpty ? dummyItem.locationName : cloudItem.locationName,
            mapImageName: nil,
            totalTrees: trees.count,
            treesToPayAttentionCount: needsAttention,
            categories: categories,
            pins: pins,
            orthomosaic: FarmOrthomosaicMapData(
                imageURL: dummyMap.imageURL,
                imagePixelWidth: dummyMap.imagePixelWidth,
                imagePixelHeight: dummyMap.imagePixelHeight,
                farmBoundary: boundary,
                zones: zones,
                trees: trees
            )
        )
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
