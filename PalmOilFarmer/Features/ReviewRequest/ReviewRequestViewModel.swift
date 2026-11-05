import Foundation
import Observation

@MainActor
@Observable
final class ReviewRequestViewModel {
    var hasConsent = false
    var showsConsentError = false
    private let isActive: () -> Bool
    private let onContinue: () -> Void

    init(isActive: @escaping () -> Bool, onContinue: @escaping () -> Void) {
        self.isActive = isActive
        self.onContinue = onContinue
    }

    func continueToContact() {
        guard isActive() else { return }
        guard hasConsent else { showsConsentError = true; return }
        showsConsentError = false
        onContinue()
    }
}
