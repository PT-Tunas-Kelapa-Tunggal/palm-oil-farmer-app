import Foundation

@MainActor
struct GardenProfileFactory {
    let source: any GardenProfileDataSource
    let reviewRepository: any FarmerReviewRepository
    let reviewRequestFactory: ReviewRequestFactory

    func makeViewModel(garden: Garden) -> GardenProfileViewModel {
        let reviewRequestFactory = self.reviewRequestFactory
        return GardenProfileViewModel(garden: garden, source: source, reviewRepository: reviewRepository,
                                      makeReviewRequest: { gardenID, isActive, onSubmitted, onClose in
            reviewRequestFactory.makeFlow(gardenID: gardenID, isActive: isActive,
                                          onSubmitted: onSubmitted, onClose: onClose)
        })
    }
}
