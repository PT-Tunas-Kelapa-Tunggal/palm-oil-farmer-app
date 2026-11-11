import Foundation

/// Stores the simulated review separately from the garden's CloudKit review.
struct PlaceholderAssessmentSubmissionRepository: AssessmentSubmissionRepository {
    private let directory: URL

    init(directory: URL = URL.applicationSupportDirectory
        .appending(path: "RequestAssessment", directoryHint: .isDirectory)
        .appending(path: "PreviewReviews", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    func submit(_ submission: AssessmentSubmission) async throws {
        try Task.checkCancellation()
        guard try loadReview(for: submission.gardenID) == nil else { return }
        try save(GardenReview(contact: submission.contact), for: submission.gardenID)
    }

    func loadReview(for gardenID: UUID) throws -> GardenReview? {
        do {
            let data = try Data(contentsOf: file(for: gardenID))
            return try JSONDecoder().decode(GardenReview.self, from: data)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        }
    }

    func advanceReview(for gardenID: UUID) throws -> GardenReview? {
        guard var review = try loadReview(for: gardenID), review.status != .completed else { return nil }
        review.advance()
        try save(review, for: gardenID)
        return review
    }

    private func save(_ review: GardenReview, for gardenID: UUID) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(review)
        #if os(iOS)
        try data.write(to: file(for: gardenID), options: [.atomic, .completeFileProtection])
        #else
        try data.write(to: file(for: gardenID), options: .atomic)
        #endif
    }

    private func file(for gardenID: UUID) -> URL {
        directory.appending(path: gardenID.uuidString + ".json", directoryHint: .notDirectory)
    }
}
