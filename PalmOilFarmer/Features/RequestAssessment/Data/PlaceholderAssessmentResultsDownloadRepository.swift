import Foundation

/// Simulates progress and keeps a local receipt for each garden.
struct PlaceholderAssessmentResultsDownloadRepository: AssessmentResultsDownloadRepository {
    static let resultByteCount: Int64 = 20_000_000

    private let directory: URL
    private let stepDelay: Duration

    init(
        directory: URL = URL.applicationSupportDirectory
            .appending(path: "RequestAssessment", directoryHint: .isDirectory)
            .appending(path: "PreviewDownloads", directoryHint: .isDirectory),
        stepDelay: Duration = .milliseconds(200)
    ) {
        self.directory = directory
        self.stepDelay = stepDelay
    }

    func completedDownload(for gardenID: UUID) throws -> AssessmentResultDownload? {
        do {
            return try JSONDecoder().decode(AssessmentResultDownload.self, from: Data(contentsOf: receiptURL(for: gardenID)))
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        }
    }

    func download(
        for gardenID: UUID,
        onProgress: @MainActor (AssessmentDownloadProgress) -> Void
    ) async throws -> AssessmentResultDownload {
        try Task.checkCancellation()
        if let receipt = try completedDownload(for: gardenID) { return receipt }

        let steps = 40
        let total = Self.resultByteCount
        let delay = stepDelay.components
        let secondsPerStep = Double(delay.seconds) + Double(delay.attoseconds) / 1e18
        for step in 0...steps {
            if step > 0 { try await Task.sleep(for: stepDelay) }
            onProgress(AssessmentDownloadProgress(
                receivedBytes: total * Int64(step) / Int64(steps),
                totalBytes: total,
                secondsRemaining: secondsPerStep * Double(steps - step)
            ))
        }

        try Task.checkCancellation()
        let receipt = AssessmentResultDownload(downloadedAt: .now, byteCount: total, localFileURL: nil)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(receipt).write(to: receiptURL(for: gardenID), options: .atomic)
        return receipt
    }

    private func receiptURL(for gardenID: UUID) -> URL {
        directory.appending(path: gardenID.uuidString + ".json", directoryHint: .notDirectory)
    }
}
