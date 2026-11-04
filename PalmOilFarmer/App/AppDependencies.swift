import SwiftData

/// The production dependency graph is assembled here, without a DI framework.
@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let reviewRepository: any FarmerReviewRepository
    let gardenStore: GardenStore

    init(modelContainer: ModelContainer, reviewRepository: any FarmerReviewRepository) {
        self.modelContainer = modelContainer
        self.reviewRepository = reviewRepository
        gardenStore = GardenStore(
            draftRepository: SwiftDataGardenDraftRepository(modelContainer: modelContainer),
            repository: reviewRepository
        )
    }

    static func live() -> AppDependencies {
        AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(),
            reviewRepository: CloudKitFarmerReviewRepository(
                containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
            )
        )
    }
}
