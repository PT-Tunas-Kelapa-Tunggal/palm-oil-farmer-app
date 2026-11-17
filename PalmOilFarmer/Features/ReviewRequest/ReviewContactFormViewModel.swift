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
    static let budgetRange: ClosedRange<Double> = 1_000_000...10_000_000
    static let budgetStep: Double = 500_000

    let gardenName: String
    let areaHectares: Double
    var name = ""
    var phone = ""
    var address = ""
    var hasConsent = false
    var fertilizerBudgetPerHectare: Double = 5_500_000
    var errorMessage: String?
    private(set) var savedContacts: [ReviewContactDetails]
    private(set) var selectedContactIndex: Int = 0
    private(set) var isEditingContact: Bool
    private(set) var isSubmitting = false
    private(set) var hasSubmitted = false
    private let isActive: () -> Bool
    private let onSubmit: (ReviewContactDetails) async throws -> Void
    private let onSubmitted: () -> Void

    init(gardenName: String = "Belakang Rumah",
         areaHectares: Double = 1.7,
         savedContacts: [ReviewContactDetails] = [],
         hasSubmitted: Bool = false,
         isActive: @escaping () -> Bool,
         onSubmit: @escaping (ReviewContactDetails) async throws -> Void,
         onSubmitted: @escaping () -> Void) {
        self.gardenName = gardenName
        self.areaHectares = areaHectares
        self.savedContacts = savedContacts
        self.isEditingContact = savedContacts.isEmpty && !hasSubmitted
        self.hasSubmitted = hasSubmitted
        self.isActive = isActive
        self.onSubmit = onSubmit
        self.onSubmitted = onSubmitted
        if let first = savedContacts.first {
            self.name = first.name
            self.phone = first.phone
            self.address = first.address
        }
    }

    var effectiveAreaHectares: Double {
        areaHectares > 0 ? areaHectares : 1.7
    }

    var totalFertilizerBudget: Double {
        fertilizerBudgetPerHectare * effectiveAreaHectares
    }

    var formattedBudgetPerHectare: String {
        Self.formatRupiah(fertilizerBudgetPerHectare)
    }

    var formattedTotalBudget: String {
        Self.formatRupiah(totalFertilizerBudget)
    }

    var formattedArea: String {
        effectiveAreaHectares.formatted(
            .number
                .locale(Locale(identifier: "id_ID"))
                .precision(.fractionLength(0...1))
        ) + " ha"
    }

    static func formatRupiah(_ amount: Double) -> String {
        "Rp" + Int(amount.rounded()).formatted(.number.locale(Locale(identifier: "id_ID")))
    }

    @discardableResult
    func saveContact() -> Bool {
        guard !isSubmitting, !hasSubmitted, isActive() else { return false }
        guard let validated = ReviewContactDetails.validated(
            name: name, phone: phone, address: address, hasConfirmedContact: true
        ) else {
            errorMessage = "Lengkapi nama, nomor telepon, dan alamat lengkap terlebih dahulu."
            return false
        }
        errorMessage = nil
        savedContacts.append(validated)
        selectedContactIndex = savedContacts.count - 1
        name = validated.name
        phone = validated.phone
        address = validated.address
        isEditingContact = false
        return true
    }

    func selectContact(at index: Int) {
        guard savedContacts.indices.contains(index) else { return }
        selectedContactIndex = index
        let contact = savedContacts[index]
        name = contact.name
        phone = contact.phone
        address = contact.address
    }

    func startAddingAnotherContact() {
        guard !isSubmitting, !hasSubmitted else { return }
        errorMessage = nil
        name = ""
        phone = ""
        address = ""
        isEditingContact = true
    }

    @discardableResult
    func cancelEditingContact() -> Bool {
        guard !savedContacts.isEmpty else { return false }
        errorMessage = nil
        selectContact(at: min(selectedContactIndex, savedContacts.count - 1))
        isEditingContact = false
        return true
    }

    func submit(closesImmediately: Bool = true) async {
        guard !isSubmitting, !hasSubmitted, isActive(), !Task.isCancelled else { return }
        if !isEditingContact, savedContacts.indices.contains(selectedContactIndex),
           name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            selectContact(at: selectedContactIndex)
        }
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
            if closesImmediately {
                onSubmitted()
            }
        } catch {
            guard isActive(), !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = error.localizedDescription
        }
    }
}
