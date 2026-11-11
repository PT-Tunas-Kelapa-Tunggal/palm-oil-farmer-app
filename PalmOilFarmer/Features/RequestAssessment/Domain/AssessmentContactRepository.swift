@MainActor
protocol AssessmentContactRepository {
    func loadContacts() throws -> [ReviewContactDetails]
    func save(_ contact: ReviewContactDetails) throws -> [ReviewContactDetails]
    func update(_ original: ReviewContactDetails, to contact: ReviewContactDetails) throws -> [ReviewContactDetails]
}
