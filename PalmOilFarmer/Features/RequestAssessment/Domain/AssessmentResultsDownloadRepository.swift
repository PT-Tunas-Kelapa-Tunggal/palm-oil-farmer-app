import Foundation

struct AssessmentDownloadProgress {
    let receivedBytes: Int64
    let totalBytes: Int64?
    let secondsRemaining: TimeInterval?

    var fraction: Double? {
        guard let totalBytes, totalBytes > 0 else { return nil }
        return min(1, max(0, Double(receivedBytes) / Double(totalBytes)))
    }
}

struct AssessmentResultDownload: Codable {
    let downloadedAt: Date
    let byteCount: Int64
    /// Set by a repository that downloads an actual result file.
    let localFileURL: URL?
}

@MainActor
protocol AssessmentResultsDownloadRepository {
    func completedDownload(for gardenID: UUID) throws -> AssessmentResultDownload?
    func download(
        for gardenID: UUID,
        onProgress: @MainActor (AssessmentDownloadProgress) -> Void
    ) async throws -> AssessmentResultDownload
}
