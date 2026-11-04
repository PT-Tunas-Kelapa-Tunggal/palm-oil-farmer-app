import Foundation

/// Home screen filter. Drafts always need mapping; other stages are labels on the cards under Semua.
enum GardenListFilter: String, CaseIterable, Identifiable {
    case all = "Semua"
    case draft = "Draf"
    case inReview = "Peninjauan"

    var id: Self { self }

    var accessibilityName: String {
        switch self {
        case .all: "Semua kebun"
        case .draft: "Lanjutkan pemetaan"
        case .inReview: "Dalam proses peninjauan"
        }
    }

    var emptyTitle: String {
        switch self {
        case .all: "Belum ada kebun terdaftar"
        case .draft: "Tidak ada draf"
        case .inReview: "Belum ada peninjauan"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all: "Daftarkan kebun Anda untuk mulai memantau kondisi kebun dan mendapatkan rekomendasi pemupukan."
        case .draft: "Kebun yang disimpan dengan \"Lakukan Nanti\" muncul di sini agar pemetaannya bisa dilanjutkan di kebun."
        case .inReview: "Lengkapi riwayat pupuk dan panen, lalu ajukan peninjauan. Kebun yang sedang ditinjau muncul di sini."
        }
    }

    var emptySymbol: String {
        switch self {
        case .all: "leaf"
        case .draft: "map"
        case .inReview: "doc.text.magnifyingglass"
        }
    }

    func includes(_ garden: Garden) -> Bool {
        switch self {
        case .all: true
        case .draft: false
        case .inReview: if case .inReview = garden.stage { true } else { false }
        }
    }

    var includesDrafts: Bool { self != .inReview }

    /// Items in this tab that need the farmer to act, for the tab's badge.
    func actionCount(gardens: [Garden], drafts: [GardenDraft]) -> Int {
        gardens.filter { includes($0) && $0.stage.needsAction }.count + (includesDrafts ? drafts.count : 0)
    }
}
