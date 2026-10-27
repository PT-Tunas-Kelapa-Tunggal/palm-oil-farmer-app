import Foundation

struct ReviewContactDetails {
    let name: String
    let phone: String
    let address: String
}

enum ReviewServiceError: LocalizedError {
    case unavailable, persistenceFailed
    var errorDescription: String? {
        switch self {
        case .unavailable: "Layanan pengajuan peninjauan belum terhubung."
        case .persistenceFailed: "Pengajuan diterima, tetapi status belum tersimpan di perangkat. Periksa koneksi layanan sebelum mencoba lagi."
        }
    }
}

