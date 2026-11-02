import Foundation
import Observation

@MainActor
@Observable
final class ReviewResultViewModel {
    enum Phase {
        case loading
        case loaded(ReviewResultContent)
        case empty
        case failed(String)
    }

    private(set) var phase = Phase.loading

    private let gardenID: UUID
    private let repository: ReviewResultRepository

    init(gardenID: UUID, repository: ReviewResultRepository) {
        self.gardenID = gardenID
        self.repository = repository
    }

    func load() async {
        phase = .loading
        do {
            if let content = try await repository.fetchContent(for: gardenID) {
                phase = .loaded(content)
            } else {
                phase = .empty
            }
        } catch {
            phase = .failed("Periksa koneksi internet, lalu coba lagi.")
        }
    }
}
