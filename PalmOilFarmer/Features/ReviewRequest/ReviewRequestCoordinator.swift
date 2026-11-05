import Foundation
import Observation

enum ReviewRequestRoute: Hashable { case contact(UUID) }

@MainActor
@Observable
final class ReviewRequestCoordinator {
    var path: [ReviewRequestRoute] = []
    private(set) var isFinished = false
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) { self.onClose = onClose }

    var currentContactID: UUID? {
        guard let route = path.last else { return nil }
        switch route { case .contact(let id): return id }
    }

    func showContact() {
        guard !isFinished, path.isEmpty else { return }
        path.append(.contact(UUID()))
    }

    func isCurrentContact(_ id: UUID) -> Bool {
        !isFinished && path.last == .contact(id)
    }

    func close() {
        guard !isFinished else { return }
        isFinished = true
        onClose()
    }
}

@MainActor
struct ReviewRequestFlow {
    let viewModel: ReviewRequestViewModel
    let coordinator: ReviewRequestCoordinator
    let makeContactFlow: (UUID) -> ReviewContactFlow
}

@MainActor
struct ReviewContactFlow {
    let viewModel: ReviewContactFormViewModel
    let close: () -> Void
    var dismissOnClose = false
}
