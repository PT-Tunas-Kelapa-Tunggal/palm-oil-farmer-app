import Foundation

// Existing reference/experiment callback APIs do not construct live services in the Views.
extension ReviewRequestView {
    init(onSubmit: @escaping (ReviewContactDetails) async throws -> Void) {
        let coordinator = ReviewRequestCoordinator(onClose: {})
        let request = ReviewRequestViewModel(isActive: { !coordinator.isFinished }, onContinue: coordinator.showContact)
        self.init(flow: ReviewRequestFlow(viewModel: request, coordinator: coordinator, makeContactFlow: { id in
            ReviewContactFlow(viewModel: ReviewContactFormViewModel(
                isActive: { request.hasConsent && coordinator.isCurrentContact(id) },
                onSubmit: onSubmit, onSubmitted: coordinator.close
            ), close: coordinator.close)
        }))
    }
}

extension ReviewContactFormView {
    init(onClose: (() -> Void)? = nil, onSubmit: @escaping (ReviewContactDetails) async throws -> Void) {
        let coordinator = ReviewRequestCoordinator(onClose: onClose ?? {})
        self.init(flow: ReviewContactFlow(
            viewModel: ReviewContactFormViewModel(isActive: { !coordinator.isFinished }, onSubmit: onSubmit, onSubmitted: {}),
            close: coordinator.close, dismissOnClose: onClose == nil
        ))
    }
}
