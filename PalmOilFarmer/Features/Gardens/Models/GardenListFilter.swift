import Foundation

/// Home screen filter. Each garden or draft is in at most one stage; a complete garden that has not
/// been submitted for review belongs to none and only appears under `all`.
enum GardenListFilter: String, CaseIterable, Identifiable {
    case all = "Semua"
    case draft = "Draf"
    case incomplete = "Lengkapi"
    case inReview = "Ditinjau"
    case results = "Hasil"

    var id: Self { self }

    var accessibilityLabel: String {
        switch self {
        case .all: "Semua kebun"
        case .draft: "Lanjutkan pemetaan"
        case .incomplete: "Lengkapi profil"
        case .inReview: "Dalam proses peninjauan"
        case .results: "Sudah punya hasil analisis"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all: "Belum ada kebun terdaftar."
        case .draft: "Tidak ada kebun yang menunggu pemetaan."
        case .incomplete: "Semua profil kebun sudah lengkap."
        case .inReview: "Tidak ada kebun dalam proses peninjauan."
        case .results: "Belum ada hasil analisis kebun."
        }
    }

    func includes(_ garden: Garden) -> Bool {
        switch self {
        case .all: true
        case .draft: false
        case .incomplete: garden.review == nil && !garden.isProfileComplete
        case .inReview: garden.review?.isInProgress == true
        case .results: garden.review?.status == .completed
        }
    }

    var includesDrafts: Bool { self == .all || self == .draft }
}

extension Garden {
    var isProfileComplete: Bool { !(fertilizerRecords ?? []).isEmpty && harvestRecord != nil }
}
