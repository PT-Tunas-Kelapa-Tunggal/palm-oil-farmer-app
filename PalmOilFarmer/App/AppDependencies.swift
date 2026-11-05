import SwiftData

/// The production dependency graph is assembled here, without a DI framework.
@MainActor
struct AppDependencies {
    let modelContainer: ModelContainer
    let reviewRepository: any FarmerReviewRepository
    let gardenStore: GardenStore
    let coordinator: AppCoordinator
    let gardenListViewModel: GardenListViewModel
    let registrationFactory: GardenRegistrationFactory
    let mappingFactory: GardenMappingFactory
    let profileFactory: GardenProfileFactory
    let submitGardenReview: SubmitGardenReview
    let reviewRequestFactory: ReviewRequestFactory

    init(modelContainer: ModelContainer, reviewRepository: any FarmerReviewRepository,
         registrationServices: @escaping () -> GardenRegistrationServices,
         mappingAuthorization: @escaping () -> any GardenLocationAuthorizing) {
        self.modelContainer = modelContainer
        self.reviewRepository = reviewRepository
        let gardenStore = GardenStore(
            draftRepository: SwiftDataGardenDraftRepository(modelContainer: modelContainer),
            repository: reviewRepository
        )
        let coordinator = AppCoordinator()
        self.gardenStore = gardenStore
        self.coordinator = coordinator
        gardenListViewModel = GardenListViewModel(source: gardenStore, onEvent: coordinator.handle)
        registrationFactory = GardenRegistrationFactory(services: registrationServices)
        mappingFactory = GardenMappingFactory(saving: gardenStore, authorization: mappingAuthorization)
        let submitGardenReview = SubmitGardenReview(gateway: gardenStore)
        self.submitGardenReview = submitGardenReview
        let reviewRequestFactory = ReviewRequestFactory(submission: submitGardenReview)
        self.reviewRequestFactory = reviewRequestFactory
        profileFactory = GardenProfileFactory(source: gardenStore, reviewRepository: reviewRepository,
                                               reviewRequestFactory: reviewRequestFactory)
    }

    static func live() -> AppDependencies {
        AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(),
            reviewRepository: CloudKitFarmerReviewRepository(
                containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
            ),
            registrationServices: GardenRegistrationFactory.liveServices,
            mappingAuthorization: { MappingLocationAuthorization() }
        )
    }
}
