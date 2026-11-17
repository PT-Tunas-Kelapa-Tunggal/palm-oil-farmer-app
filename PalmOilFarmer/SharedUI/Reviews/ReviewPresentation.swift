import Foundation

// Existing presentation helpers relocated without changing their implementation.
extension ReviewTimeline {
    func entries(for currentStatus: ReviewStatus) -> [ReviewTimelineEntry] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMMM yyyy HH:mm 'WIB'"

        let scheduledDateString = scheduledFor.map {
            let df = DateFormatter()
            df.locale = Locale(identifier: "id_ID")
            df.dateFormat = "EEEE, d MMMM yyyy"
            return df.string(from: $0)
        } ?? "jadwal yang disepakati"

        let titles = [
            "Permintaan Peninjauan\nBerhasil Diajukan",
            currentStatus.rawValue >= 1 ? "Kunjungan dijadwalkan" : "Penjadwalan Kunjungan",
            currentStatus.rawValue >= 2 ? "Peninjauan berlangsung" : "Peninjauan Kebun",
            currentStatus == .completed ? "Peninjauan Selesai" : "Pemrosesan Hasil Tinjauan"
        ]

        let messages = [
            "Permintaan Anda sudah dikirim. Petugas akan menghubungi Anda dalam 1 hari kerja untuk menentukan jadwal kunjungan ke kebun.",
            currentStatus.rawValue >= 1
                ? "Petugas akan datang ke kebun pada \(scheduledDateString). Pastikan Anda atau perwakilan dapat mendampingi di lokasi."
                : "Petugas dan Anda menyepakati hari kunjungan ke kebun.",
            currentStatus.rawValue >= 2
                ? "Petugas sudah mengunjungi kebun Anda. Hasil peninjauan sedang disusun dan akan muncul di sini dalam 1 hari kerja."
                : "Petugas datang ke kebun untuk memeriksa kondisi tanaman dan lahan.",
            currentStatus == .completed
                ? "Hasil peninjauan kebun Anda sudah tersedia. Analisis dan rekomendasi perawatan dapat dilihat di halaman Kebun."
                : "Sistem menyusun hasil kunjungan menjadi analisis dan rekomendasi perawatan."
        ]

        let dates: [String?] = [
            formatter.string(from: submittedAt),
            scheduledFor.map { formatter.string(from: $0) },
            inReviewAt.map { formatter.string(from: $0) },
            completedAt.map { formatter.string(from: $0) }
        ]

        return (0..<4).map { index in
            ReviewTimelineEntry(
                id: index,
                date: index <= currentStatus.rawValue ? dates[index] : nil,
                title: titles[index],
                message: messages[index],
                isReached: index <= currentStatus.rawValue
            )
        }
    }
}

extension ReviewStatus {
    public var title: String {
        switch self {
        case .submitted: return "Berhasil Diajukan"
        case .scheduled: return "Kunjungan Dijadwalkan"
        case .inReview: return "Peninjauan Berlangsung"
        case .completed: return "Peninjauan Selesai"
        }
    }
}
