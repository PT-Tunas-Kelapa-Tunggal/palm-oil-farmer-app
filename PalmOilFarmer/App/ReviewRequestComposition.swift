import Foundation

@MainActor
struct ReviewRequestFactory {
    let submission: SubmitGardenReview

    func makeFlow(gardenID: UUID,
                  gardenName: String = "Belakang Rumah",
                  areaHectares: Double = 1.7,
                  isActive: @escaping () -> Bool,
                  onSubmitted: @escaping (PlantationReviewRequest) -> Void,
                  onClose: @escaping () -> Void) -> ReviewRequestFlow {
        let coordinator = ReviewRequestCoordinator(onClose: onClose)
        let request = ReviewRequestViewModel(isActive: { !coordinator.isFinished && isActive() }, onContinue: coordinator.showContact)
        return ReviewRequestFlow(viewModel: request, coordinator: coordinator, makeContactFlow: { id in
            let isCurrent = { request.hasConsent && coordinator.isCurrentContact(id) && isActive() }
            let contact = ReviewContactFormViewModel(
                gardenName: gardenName,
                areaHectares: areaHectares,
                isActive: isCurrent,
                onSubmit: { contact in
                    let saved = try await submission.execute(gardenID: gardenID, contact: contact)
                    if isCurrent() { onSubmitted(saved) }
                },
                onSubmitted: coordinator.close
            )
            return ReviewContactFlow(viewModel: contact, close: coordinator.close)
        })
    }
}
