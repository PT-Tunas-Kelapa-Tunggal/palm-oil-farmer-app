import Foundation

struct SubmissionSuccessViewModel {
    let gardenName: String
    let isPreview: Bool

    var message: String {
        if isPreview {
            return String(localized: "Pratinjau pengajuan untuk \(gardenName). Data belum dikirim.")
        }
        return String(localized: "Pengajuan peninjauan untuk \(gardenName) sudah kami terima.")
    }
}
