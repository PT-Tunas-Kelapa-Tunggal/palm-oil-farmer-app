import Foundation

struct AssessmentStatusViewModel {
    struct Step: Identifiable {
        let id: ReviewStatus
        let title: String
        let message: String
        let date: String?
        let phase: Phase

        enum Phase { case finished, current, upcoming }
    }

    let review: GardenReview
    var detailEvents: [ProgressionStatusDetailEvent]? = nil

    var sheetHeight: Double {
        switch review.status {
        case .submitted: 469
        case .scheduled: 489
        case .inReview, .completed: 509
        }
    }

    var steps: [Step] {
        var customDates: [ReviewStatus: String] = [:]
        var customMessages: [ReviewStatus: String] = [:]
        if let detailEvents {
            for event in detailEvents {
                let stage: ReviewStatus?
                switch event.title.lowercased() {
                case "sent": stage = .submitted
                case "scheduled": stage = .scheduled
                case "in progress", "inprogress": stage = .inReview
                case "finished": stage = .completed
                default: stage = nil
                }
                if let stage {
                    customDates[stage] = Self.timestamp.string(from: event.dateTime)
                    if !event.desc.isEmpty {
                        customMessages[stage] = event.desc
                    }
                }
            }
        }

        return ReviewStatus.allCases.map { stage in
            let phase: Step.Phase
            if stage == review.status {
                phase = .current
            } else {
                phase = stage.rawValue < review.status.rawValue ? .finished : .upcoming
            }

            let (defaultTitle, defaultMessage) = copy(for: stage, phase: phase)
            let message = (phase != .upcoming && customMessages[stage] != nil) ? customMessages[stage]! : defaultMessage
            let date = phase == .upcoming ? nil : (customDates[stage] ?? review.date(for: stage).map(Self.timestamp.string(from:)))

            return Step(
                id: stage,
                title: defaultTitle,
                message: message,
                date: date,
                phase: phase
            )
        }
    }

    private func copy(for stage: ReviewStatus, phase: Step.Phase) -> (String, String) {
        switch (stage, phase) {
        case (.submitted, .current):
            ("Pengajuan terkirim", "Petugas akan menghubungi narahubung dalam 1 hari kerja untuk menentukan jadwal kunjungan.")
        case (.submitted, _):
            ("Pengajuan terkirim", "Petugas menghubungi narahubung untuk menentukan jadwal kunjungan.")
        case (.scheduled, .upcoming):
            ("Penjadwalan kunjungan", "Petugas dan narahubung menyepakati hari kunjungan ke kebun.")
        case (.scheduled, .current):
            ("Kunjungan dijadwalkan", "Petugas datang pada \(visitDate). Pastikan Anda atau narahubung bisa mendampingi di kebun.")
        case (.scheduled, .finished):
            ("Kunjungan dijadwalkan", "Kunjungan disepakati pada \(visitDate).")
        case (.inReview, .upcoming):
            ("Pemotretan kebun", "Petugas memotret seluruh kebun dengan drone.")
        case (.inReview, .current):
            ("Pemotretan berlangsung", "Petugas sedang memotret kebun dengan drone. Hasil diolah setelah pemotretan selesai.")
        case (.inReview, .finished):
            ("Kebun selesai dipotret", "Seluruh kebun sudah dipotret dengan drone.")
        case (.completed, .upcoming):
            ("Hasil peninjauan", "Peta kebun dan rekomendasi pupuk per area.")
        case (.completed, _):
            ("Hasil peninjauan tersedia", "Unduh hasilnya di halaman Detail Kebun agar peta kebun dan rekomendasi pupuk bisa dibuka tanpa sinyal.")
        }
    }

    private var visitDate: String {
        review.visitDate.map(Self.visit.string(from:)) ?? "hari yang disepakati"
    }

    private static let timestamp = formatter("d MMM yyyy, HH.mm 'WIB'")
    private static let visit = formatter("EEEE, d MMMM yyyy")

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.timeZone = TimeZone(identifier: "Asia/Jakarta")
        formatter.dateFormat = format
        return formatter
    }
}
