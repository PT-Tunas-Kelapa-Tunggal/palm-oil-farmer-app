import Foundation

enum ReviewServiceError: LocalizedError {
    case unavailable
    var errorDescription: String? { "Layanan pengajuan peninjauan belum terhubung." }
}
