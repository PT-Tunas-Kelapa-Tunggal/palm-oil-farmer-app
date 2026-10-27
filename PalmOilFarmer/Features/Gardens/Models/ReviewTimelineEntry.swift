import Foundation

struct ReviewTimelineEntry: Identifiable, Codable {
    let id: Int
    let date: String?
    let title: String
    let message: String
    let isReached: Bool

    static func referenceEntries(for status: ReviewStatus) -> [ReviewTimelineEntry] {
        let titles = [
            "Permintaan Peninjauan\nBerhasil Diajukan",
            status.rawValue >= 1 ? "Kunjungan dijadwalkan" : "Penjadwalan Kunjungan",
            status.rawValue >= 2 ? "Peninjauan berlangsung" : "Peninjauan Kebun",
            status == .completed ? "Peninjauan Selesai" : "Pemrosesan Hasil Tinjauan"
        ]
        let messages = [
            "Permintaan Anda sudah dikirim. Petugas akan menghubungi Anda dalam 1 hari kerja untuk menentukan jadwal kunjungan ke kebun.",
            status.rawValue >= 1
                ? "Petugas akan datang ke kebun pada Senin, 20 November 2026. Pastikan Anda atau perwakilan dapat mendampingi di lokasi."
                : "Petugas dan Anda menyepakati hari kunjungan ke kebun.",
            status.rawValue >= 2
                ? "Petugas sudah mengunjungi kebun Anda. Hasil peninjauan sedang disusun dan akan muncul di sini dalam 1 hari kerja."
                : "Petugas datang ke kebun untuk memeriksa kondisi tanaman dan lahan.",
            status == .completed
                ? "Hasil peninjauan kebun Anda sudah tersedia. Analisis dan rekomendasi perawatan dapat dilihat di halaman Kebun."
                : "Sistem menyusun hasil kunjungan menjadi analisis dan rekomendasi perawatan."
        ]
        return (0..<4).map { index in
            ReviewTimelineEntry(
                id: index,
                date: index <= status.rawValue
                    ? (index == status.rawValue ? "Hari Ini" : ["19 November 2026 13:48 WIB", "20 November 2026 07:14 WIB", "20 November 2026 19:34 WIB", ""][index])
                    : nil,
                title: titles[index], message: messages[index], isReached: index <= status.rawValue
            )
        }
    }
}
