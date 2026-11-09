import Foundation

// Existing reference/experiment callback APIs do not construct live services in the Views.
extension ReviewRequestView {
    init(gardenName: String = "Belakang Rumah",
         areaHectares: Double = 1.7,
         savedContacts: [ReviewContactDetails] = [],
         onSubmit: @escaping (ReviewContactDetails) async throws -> Void) {
        let coordinator = ReviewRequestCoordinator(onClose: {})
        let request = ReviewRequestViewModel(isActive: { !coordinator.isFinished }, onContinue: coordinator.showContact)
        self.init(flow: ReviewRequestFlow(viewModel: request, coordinator: coordinator, makeContactFlow: { id in
            ReviewContactFlow(viewModel: ReviewContactFormViewModel(
                gardenName: gardenName,
                areaHectares: areaHectares,
                savedContacts: savedContacts,
                isActive: { request.hasConsent && coordinator.isCurrentContact(id) },
                onSubmit: onSubmit, onSubmitted: coordinator.close
            ), close: coordinator.close)
        }))
    }
}

extension ReviewContactFormView {
    init(gardenName: String = "Belakang Rumah",
         areaHectares: Double = 1.7,
         savedContacts: [ReviewContactDetails] = [],
         onClose: (() -> Void)? = nil,
         onSubmit: @escaping (ReviewContactDetails) async throws -> Void) {
        let coordinator = ReviewRequestCoordinator(onClose: onClose ?? {})
        self.init(flow: ReviewContactFlow(
            viewModel: ReviewContactFormViewModel(
                gardenName: gardenName,
                areaHectares: areaHectares,
                savedContacts: savedContacts,
                isActive: { !coordinator.isFinished },
                onSubmit: onSubmit,
                onSubmitted: {}
            ),
            close: coordinator.close, dismissOnClose: onClose == nil
        ))
    }
}
