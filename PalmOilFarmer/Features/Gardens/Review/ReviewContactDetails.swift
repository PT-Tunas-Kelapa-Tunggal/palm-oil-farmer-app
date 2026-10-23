import Foundation

struct ReviewContactDetails {
    let name: String
    let phone: String
    let address: String
}

enum ReviewServiceError: LocalizedError {
    case unavailable
    var errorDescription: String? { "Layanan pengajuan peninjauan belum terhubung." }
}

