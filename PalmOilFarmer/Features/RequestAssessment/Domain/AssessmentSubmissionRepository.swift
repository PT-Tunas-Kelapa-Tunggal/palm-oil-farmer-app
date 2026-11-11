import Foundation

struct AssessmentSubmission {
    let gardenID: UUID
    let contact: ReviewContactDetails
    let fertilizerBudgetPerHectare: Int
}

@MainActor
protocol AssessmentSubmissionRepository {
    func submit(_ submission: AssessmentSubmission) async throws
}
