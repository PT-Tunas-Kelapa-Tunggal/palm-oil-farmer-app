import Foundation
import Observation

/// ViewModel managing state and data loading for the Assessment Results Overview screen.
@Observable
@MainActor
public final class ResultOverviewViewModel {
    private let repository: any ResultOverviewRepositoryProtocol
    private let farmGreenIndexRepository: any FarmGreenIndexRepositoryProtocol

    public let gardenId: String
    private let gardenName: String?
    private let locationName: String?
    public var overview: ResultOverviewItem?
    public var farmBoundary: [FarmMapCoordinate] = []
    public var isLoading: Bool = false
    public var errorMessage: String?

    public init(
        repository: any ResultOverviewRepositoryProtocol = DummyResultOverviewRepository(),
        farmGreenIndexRepository: any FarmGreenIndexRepositoryProtocol = DummyFarmGreenIndexRepository(),
        gardenId: String = "garden-default",
        gardenName: String? = nil,
        locationName: String? = nil
    ) {
        self.repository = repository
        self.farmGreenIndexRepository = farmGreenIndexRepository
        self.gardenId = gardenId
        self.gardenName = gardenName
        self.locationName = locationName
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedOverview = try await repository.fetchOverview(for: gardenId)
            let farmIndex = try await farmGreenIndexRepository.fetchFarmGreenIndex(for: gardenId)
            farmBoundary = farmIndex.orthomosaic?.farmBoundary ?? []
            let deficientTreeCount = farmIndex.categories
                .filter { $0.category == .defisiensi || $0.category == .tidakWajar }
                .reduce(0) { $0 + $1.treeCount }
            let greenness = FarmGreennessSummary(
                affectedTreeCount: deficientTreeCount,
                totalTreeCount: farmIndex.totalTrees,
                statusDescription: "pohon terindikasi kekurangan nutrisi"
            )
            overview = fetchedOverview.replacingGardenDetails(
                name: gardenName,
                location: locationName,
                greenness: greenness
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refresh() async {
        await load()
    }
}

