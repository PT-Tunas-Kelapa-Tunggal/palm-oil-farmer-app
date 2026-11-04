import SwiftUI

// Compatibility for existing standalone/reference screens and the team-owned
// experiment. Production injects AppDependencies explicitly instead.
extension CloudKitFarmerReviewRepository {
    public static let shared = CloudKitFarmerReviewRepository(
        containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
    )
}

extension GardenStore {
    convenience init() {
        self.init(
            draftRepository: SwiftDataGardenDraftRepository(
                modelContainer: AppConfiguration.makeModelContainer()
            ),
            repository: CloudKitFarmerReviewRepository.shared
        )
    }
}

private struct FarmerReviewRepositoryKey: EnvironmentKey {
    static let defaultValue: any FarmerReviewRepository = CloudKitFarmerReviewRepository.shared
}

extension EnvironmentValues {
    var farmerReviewRepository: any FarmerReviewRepository {
        get { self[FarmerReviewRepositoryKey.self] }
        set { self[FarmerReviewRepositoryKey.self] = newValue }
    }
}
