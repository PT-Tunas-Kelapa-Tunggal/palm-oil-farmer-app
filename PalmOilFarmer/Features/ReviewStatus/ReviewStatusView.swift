import SwiftUI

struct ReviewTimelineEntry: Identifiable {
    let id: Int
    let date: String?
    let title: String
    let message: String
    let isReached: Bool

    static func referenceEntries(for status: ReviewStatus) -> [ReviewTimelineEntry] {
        let dates = ["19 November 2026 13:48 WIB", "20 November 2026 07:14 WIB", "20 November 2026 19:34 WIB", ""]
        return entries(status: status, visit: "Senin, 20 November 2026") { index in
            index == status.rawValue ? "Hari Ini" : dates[index]
        }
    }

    static func entries(for review: GardenReview, now: Date = .now) -> [ReviewTimelineEntry] {
        let visit = review.visitDate.map { $0.formatted(ReviewDateFormat.visit) } ?? ""
        return entries(status: review.status, visit: visit) { index in
            guard let status = ReviewStatus(rawValue: index), let date = review.date(for: status) else { return nil }
            if status == review.status && Calendar.current.isDate(date, inSameDayAs: now) { return "Hari Ini" }
            return date.formatted(ReviewDateFormat.timestamp)
        }
    }

    /// `date` returns the label for a reached stage index.
    private static func entries(status: ReviewStatus, visit: String,
                                date: (Int) -> String?) -> [ReviewTimelineEntry] {
        let titles = [
            "Permintaan Peninjauan\nBerhasil Diajukan",
            status.rawValue >= 1 ? "Kunjungan dijadwalkan" : "Penjadwalan Kunjungan",
            status.rawValue >= 2 ? "Peninjauan berlangsung" : "Peninjauan Kebun",
            status == .completed ? "Peninjauan Selesai" : "Pemrosesan Hasil Tinjauan"
        ]
        let messages = [
            "Permintaan Anda sudah dikirim. Petugas akan menghubungi Anda dalam 1 hari kerja untuk menentukan jadwal kunjungan ke kebun.",
            status.rawValue >= 1
                ? "Petugas akan datang ke kebun pada \(visit). Pastikan Anda atau perwakilan dapat mendampingi di lokasi."
                : "Petugas dan Anda menyepakati hari kunjungan ke kebun.",
            status.rawValue >= 2
                ? "Petugas sudah mengunjungi kebun Anda. Hasil peninjauan sedang disusun dan akan muncul di sini dalam 1 hari kerja."
                : "Petugas datang ke kebun untuk memeriksa kondisi tanaman dan lahan.",
            status == .completed
                ? "Hasil peninjauan kebun Anda sudah tersedia. Analisis dan rekomendasi perawatan dapat dilihat di halaman Kebun."
                : "Sistem menyusun hasil kunjungan menjadi analisis dan rekomendasi perawatan."
        ]
        return (0..<4).map { index in
            let isReached = index <= status.rawValue
            return ReviewTimelineEntry(id: index, date: isReached ? date(index) : nil,
                                       title: titles[index], message: messages[index], isReached: isReached)
        }
    }
}

enum ReviewDateFormat {
    static let jakarta = TimeZone(identifier: "Asia/Jakarta") ?? .current
    static let indonesian = Locale(identifier: "id_ID")

    static var timestamp: Date.VerbatimFormatStyle {
        Date.VerbatimFormatStyle(
            format: "\(day: .defaultDigits) \(month: .wide) \(year: .defaultDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits) WIB",
            locale: indonesian, timeZone: jakarta, calendar: Calendar(identifier: .gregorian)
        )
    }

    static var visit: Date.VerbatimFormatStyle {
        Date.VerbatimFormatStyle(
            format: "\(weekday: .wide), \(day: .defaultDigits) \(month: .wide) \(year: .defaultDigits)",
            locale: indonesian, timeZone: jakarta, calendar: Calendar(identifier: .gregorian)
        )
    }
}

struct ReviewStatusView: View {
    let gardenName: String
    let status: ReviewStatus
    let entries: [ReviewTimelineEntry]
    var resultsDownloaded = false
    /// User testing only: a long press on the header moves the review to its next stage.
    var onAdvance: (() -> Void)? = nil
    var onDownloaded: () -> Void = {}
    let onViewResults: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var download: Double?
    @State private var advanceCount = 0

    private static let downloadMB = 20.0
    private static let downloadSeconds = 8.0

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Status Pengajuan", systemImage: "chevron.left",
                         subtitle: "Kebun " + gardenName, onClose: { dismiss() })
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 1.5) {
                    guard status != .completed, let onAdvance else { return }
                    onAdvance()
                    advanceCount += 1
                }
                .sensoryFeedback(.success, trigger: advanceCount)
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(entries) { entry in
                        ReviewTimelineRow(entry: entry, isLast: entry.id == entries.last?.id)
                    }
                }
                .background(alignment: .leading) {
                    Rectangle().fill(.secondary).frame(width: 1)
                        .padding(.top, 34).padding(.bottom, -24).offset(x: 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
            if let download {
                downloadProgress(download)
            } else if status == .completed {
                PrimaryActionButton(title: resultsDownloaded ? "Lihat hasil" : "Lihat & unduh hasil",
                                    systemImage: resultsDownloaded ? "chevron.right" : "document.fill",
                                    imagePlacement: .trailing) {
                    if resultsDownloaded { onViewResults() } else { download = 0 }
                }
                .padding(.horizontal, 24).padding(.vertical, 8)
            }
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: download == nil) {
            guard download != nil else { return }
            await simulateDownload()
        }
    }

    private func downloadProgress(_ fraction: Double) -> some View {
        let received = Int(fraction * Self.downloadMB)
        let remaining = Int(((1 - fraction) * Self.downloadSeconds).rounded(.up))
        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Mengunduh hasil peninjauan").font(.headline)
                HStack(spacing: 8) {
                    ProgressView(value: fraction)
                        .tint(.secondary)
                        .accessibilityLabel("Unduhan hasil peninjauan")
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                }
                HStack {
                    Text("\(received) MB dari \(Int(Self.downloadMB)) MB")
                    Spacer()
                    Text(remaining > 0 ? "sekitar \(remaining) detik lagi" : "Selesai")
                }
                .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(16)
            .background(KropsTheme.cardFill, in: RoundedRectangle(cornerRadius: 24))
            Text("Anda dapat keluar dari halaman ini. Setelah selesai diunduh, hasil peninjauan dapat dibuka tanpa sinyal internet.")
                .font(.footnote).foregroundStyle(.secondary)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    /// No result service exists yet; the download is simulated so the flow can be tested.
    @MainActor
    private func simulateDownload() async {
        let steps = 40
        for step in 1...steps {
            do { try await Task.sleep(for: .seconds(Self.downloadSeconds / Double(steps))) } catch { return }
            download = Double(step) / Double(steps)
        }
        onDownloaded()
        download = nil
        onViewResults()
    }
}

struct ReviewTimelineRow: View {
    let entry: ReviewTimelineEntry
    var isLast = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Rectangle()
                .fill(.clear)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .padding(.top, entry.date == nil ? 12 : 34)
                .overlay(alignment: .top) {
                    Circle()
                        .fill(entry.isReached ? KropsTheme.primary : Color.secondary)
                        .frame(width: entry.isReached ? 20 : 12, height: entry.isReached ? 20 : 12)
                        .offset(y: entry.date == nil ? 7 : 24)
                }
                .frame(width: 20)
                .padding(.bottom, isLast ? 0 : -24)

            VStack(alignment: .leading, spacing: 8) {
                if let date = entry.date {
                    Text(date).font(.footnote).foregroundStyle(.secondary)
                }
                Text(entry.title)
                    .font(entry.isReached ? .title2.weight(.semibold) : .headline)
                    .foregroundStyle(entry.isReached ? .primary : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(entry.message)
                    .font(entry.isReached ? .body : .subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Status · Submitted") {
    ReviewStatusView(gardenName: "Belakang Rumah", status: .submitted,
                     entries: ReviewTimelineEntry.referenceEntries(for: .submitted), onViewResults: {})
}
#Preview("Status · Scheduled") {
    ReviewStatusView(gardenName: "Belakang Rumah", status: .scheduled,
                     entries: ReviewTimelineEntry.referenceEntries(for: .scheduled), onViewResults: {})
}
#Preview("Status · In Review") {
    ReviewStatusView(gardenName: "Belakang Rumah", status: .inReview,
                     entries: ReviewTimelineEntry.referenceEntries(for: .inReview), onViewResults: {})
}
#Preview("Status · Completed") {
    ReviewStatusView(gardenName: "Belakang Rumah", status: .completed,
                     entries: ReviewTimelineEntry.referenceEntries(for: .completed), onViewResults: {})
}
#Preview("Timeline Row", traits: .sizeThatFitsLayout) {
    ReviewTimelineRow(entry: ReviewTimelineEntry.referenceEntries(for: .submitted)[0])
        .padding(24).frame(width: 402)
}
