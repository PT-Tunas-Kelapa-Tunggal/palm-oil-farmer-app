import Foundation
import Observation

@MainActor
@Observable
final class AssessmentOverviewViewModel {
    static let budgetRange = 1_000_000...10_000_000
    static let budgetStep = 500_000

    private(set) var contacts: [ReviewContactDetails] = []
    private(set) var selectedContactIndex: Int?
    private(set) var budgetPerHectare = (budgetRange.lowerBound + budgetRange.upperBound) / 2
    private(set) var isSubmitting = false
    private(set) var hasSubmitted = false
    var isConfirmed = false
    var submissionError: String?

    let areaHectares: Double
    private let gardenID: UUID
    private let contactRepository: any AssessmentContactRepository
    private let submissionRepository: any AssessmentSubmissionRepository

    init(
        gardenID: UUID,
        areaHectares: Double,
        contactRepository: any AssessmentContactRepository,
        submissionRepository: any AssessmentSubmissionRepository
    ) {
        self.gardenID = gardenID
        self.areaHectares = areaHectares
        self.contactRepository = contactRepository
        self.submissionRepository = submissionRepository
    }

    var totalBudget: Double { Double(budgetPerHectare) * areaHectares }
    var hasValidArea: Bool { areaHectares > 0 && totalBudget.isFinite }

    var canSubmit: Bool {
        selectedContactIndex != nil && hasValidArea && isConfirmed && !isSubmitting && !hasSubmitted
    }

    var budgetText: String { formatRupiah(Double(budgetPerHectare)) }
    var totalText: String { hasValidArea ? formatRupiah(totalBudget) : "—" }
    var areaText: String {
        guard hasValidArea else { return "—" }
        return areaHectares.formatted(.number.locale(Self.indonesian).precision(.fractionLength(0...2))) + " ha"
    }

    var budgetProgress: Double {
        let range = Self.budgetRange
        return Double(budgetPerHectare - range.lowerBound) / Double(range.upperBound - range.lowerBound)
    }

    func loadContacts() throws {
        contacts = try contactRepository.loadContacts()
        selectedContactIndex = contacts.indices.last
        isConfirmed = false
    }

    func saveContact(name: String, phone: String, address: String) throws {
        let contact = ReviewContactDetails(name: name, phone: phone, address: address)
        contacts = try contactRepository.save(contact)
        selectedContactIndex = contacts.firstIndex(of: contact)
        isConfirmed = false
    }

    func updateContact(_ original: ReviewContactDetails, name: String, phone: String, address: String) throws {
        let contact = ReviewContactDetails(name: name, phone: phone, address: address)
        let selection = selectedContactIndex.map { contacts[$0] }
        contacts = try contactRepository.update(original, to: contact)
        selectedContactIndex = (selection == original ? contact : selection).flatMap { contacts.firstIndex(of: $0) }
        if selection == original, original != contact { isConfirmed = false }
    }

    func selectContact(at index: Int) {
        guard contacts.indices.contains(index), selectedContactIndex != index,
              !isSubmitting, !hasSubmitted else { return }
        selectedContactIndex = index
        isConfirmed = false
    }

    func setBudgetProgress(_ progress: Double) {
        let range = Self.budgetRange
        let clamped = min(max(progress, 0), 1)
        let steps = Double(range.upperBound - range.lowerBound) / Double(Self.budgetStep)
        setBudget(range.lowerBound + Int((clamped * steps).rounded()) * Self.budgetStep)
    }

    func adjustBudget(by steps: Int) {
        setBudget(budgetPerHectare + steps * Self.budgetStep)
    }

    func submit() async {
        guard canSubmit, let index = selectedContactIndex else { return }
        isSubmitting = true
        submissionError = nil
        defer { isSubmitting = false }
        do {
            let submission = AssessmentSubmission(
                gardenID: gardenID,
                contact: contacts[index],
                fertilizerBudgetPerHectare: budgetPerHectare
            )
            try await submissionRepository.submit(submission)
            hasSubmitted = true
        } catch is CancellationError {
            return
        } catch {
            submissionError = error.localizedDescription
        }
    }

    private func setBudget(_ amount: Int) {
        let range = Self.budgetRange
        let clamped = min(max(amount, range.lowerBound), range.upperBound)
        guard clamped != budgetPerHectare, !isSubmitting, !hasSubmitted else { return }
        budgetPerHectare = clamped
        isConfirmed = false
    }

    private static let indonesian = Locale(identifier: "id_ID")

    private func formatRupiah(_ amount: Double) -> String {
        "Rp" + amount.formatted(.number.locale(Self.indonesian).precision(.fractionLength(0)))
    }
}
