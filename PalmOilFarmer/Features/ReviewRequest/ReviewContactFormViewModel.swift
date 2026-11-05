import Foundation
import Observation

enum ReviewContactField: CaseIterable {
    case name, phone, address

    var next: ReviewContactField? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
        return all[index + 1]
    }
}

@MainActor
@Observable
final class ReviewContactFormViewModel {
    var name = ""
    var phone = ""
    var address = ""
    var hasConsent = false
    var errorMessage: String?
    private(set) var isSubmitting = false
    private(set) var hasSubmitted = false
    private let isActive: () -> Bool
    private let onSubmit: (ReviewContactDetails) async throws -> Void
    private let onSubmitted: () -> Void

    init(isActive: @escaping () -> Bool, onSubmit: @escaping (ReviewContactDetails) async throws -> Void,
         onSubmitted: @escaping () -> Void) {
        self.isActive = isActive
        self.onSubmit = onSubmit
        self.onSubmitted = onSubmitted
    }

    func submit() async {
        guard !isSubmitting, !hasSubmitted, isActive(), !Task.isCancelled else { return }
        guard let contact = ReviewContactDetails.validated(
            name: name, phone: phone, address: address, hasConfirmedContact: hasConsent
        ) else {
            errorMessage = "Lengkapi nama, nomor telepon, alamat rumah, dan persetujuan terlebih dahulu."
            return
        }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await onSubmit(contact)
            hasSubmitted = true
            guard isActive(), !Task.isCancelled else { return }
            onSubmitted()
        } catch {
            guard isActive(), !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = error.localizedDescription
        }
    }
}
