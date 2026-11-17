import Foundation

/// The application gateway publishes saved reviews and evicts local drafts before returning success.
@MainActor
protocol ReviewSubmissionGateway {
    func garden(for id: UUID) -> Garden?
    func submitReview(for garden: Garden, contact: ReviewContactDetails) async throws -> PlantationReviewRequest
}

enum ReviewSubmissionError: LocalizedError {
    case gardenUnavailable, profileIncomplete, alreadySubmitted, inProgress

    var errorDescription: String? {
        switch self {
        case .gardenUnavailable: "Kebun tidak ditemukan. Buka kembali profil kebun lalu coba lagi."
        case .profileIncomplete: "Lengkapi riwayat pupuk dan panen sebelum mengajukan peninjauan."
        case .alreadySubmitted: "Kebun ini sudah diajukan untuk peninjauan."
        case .inProgress: "Pengajuan untuk kebun ini sedang dikirim. Tunggu hingga proses selesai."
        }
    }
}

@MainActor
final class SubmitGardenReview {
    private let gateway: any ReviewSubmissionGateway
    private var inFlightGardenIDs: Set<UUID> = []

    init(gateway: any ReviewSubmissionGateway) { self.gateway = gateway }

    func execute(gardenID: UUID, contact: ReviewContactDetails) async throws -> PlantationReviewRequest {
        try Task.checkCancellation()
        guard !inFlightGardenIDs.contains(gardenID) else { throw ReviewSubmissionError.inProgress }
        guard let garden = gateway.garden(for: gardenID) else { throw ReviewSubmissionError.gardenUnavailable }
        guard garden.review == nil else { throw ReviewSubmissionError.alreadySubmitted }
        guard garden.isProfileComplete else { throw ReviewSubmissionError.profileIncomplete }
        inFlightGardenIDs.insert(gardenID)
        defer { inFlightGardenIDs.remove(gardenID) }
        // Do not turn confirmed remote success into cancellation after the gateway commits it.
        return try await gateway.submitReview(for: garden, contact: contact)
    }
}
