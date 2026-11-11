import Foundation
import Observation

@MainActor
@Observable
final class AssessmentResultsViewModel {
    enum State {
        case ready
        case downloading(AssessmentDownloadProgress)
        case downloaded(AssessmentResultDownload)
    }

    enum Confirmation: String, Identifiable {
        case reviewCompleted
        case downloadCompleted

        var id: Self { self }
    }

    private let repository: any AssessmentResultsDownloadRepository
    let expectedByteCount: Int64?
    private(set) var state: State = .ready
    var confirmation: Confirmation?
    var showsDownloadError = false

    @ObservationIgnored private var downloadTask: Task<Void, Never>?
    private var gardenID: UUID?
    @ObservationIgnored private var downloadID: UUID?

    init(repository: any AssessmentResultsDownloadRepository, expectedByteCount: Int64? = nil) {
        self.repository = repository
        self.expectedByteCount = expectedByteCount
    }

    var downloadWasSimulated: Bool {
        guard case .downloaded(let receipt) = state else { return false }
        return receipt.localFileURL == nil
    }

    func load(for gardenID: UUID) {
        guard self.gardenID != gardenID else { return }
        downloadTask?.cancel()
        downloadTask = nil
        downloadID = nil
        confirmation = nil
        showsDownloadError = false
        self.gardenID = gardenID
        do {
            state = try repository.completedDownload(for: gardenID).map(State.downloaded) ?? .ready
        } catch {
            state = .ready
            showsDownloadError = true
        }
    }

    func startDownload() {
        guard case .ready = state, let gardenID else { return }
        showsDownloadError = false
        state = .downloading(.init(receivedBytes: 0, totalBytes: expectedByteCount, secondsRemaining: nil))
        let downloadID = UUID()
        self.downloadID = downloadID
        downloadTask = Task {
            defer {
                if self.downloadID == downloadID {
                    self.downloadID = nil
                    downloadTask = nil
                }
            }
            do {
                let receipt = try await repository.download(for: gardenID) { progress in
                    guard self.downloadID == downloadID, !Task.isCancelled else { return }
                    self.state = .downloading(progress)
                }
                try Task.checkCancellation()
                guard self.downloadID == downloadID else { return }
                state = .downloaded(receipt)
                confirmation = .downloadCompleted
            } catch {
                guard self.downloadID == downloadID else { return }
                state = .ready
                showsDownloadError = !Task.isCancelled && !(error is CancellationError)
            }
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
    }
}
