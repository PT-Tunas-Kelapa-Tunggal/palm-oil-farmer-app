import SwiftUI

enum ReviewStatus: Int, CaseIterable, Codable {
    case submitted, scheduled, inReview, completed
}

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

struct ReviewStatusView: View {
    let gardenName: String
    let status: ReviewStatus
    let entries: [ReviewTimelineEntry]
    var downloadURL: URL? = nil
    var onRefresh: () async -> Void = {}
    var onAdvanceDemo: (() -> Void)? = nil
    let onViewResults: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var download = ReviewReportDownload.shared

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Status Pengajuan", systemImage: "chevron.left",
                         subtitle: "Kebun " + gardenName,
                         onTitleLongPress: onAdvanceDemo, onClose: { dismiss() })
            if onAdvanceDemo != nil {
                Text("Simulasi · belum dikirim ke server")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(entries) { entry in
                        ReviewTimelineRow(entry: entry, isLast: entry.id == entries.last?.id)
                    }
                }
                .background(alignment: .leading) {
                    Rectangle().fill(.primary).frame(width: 1)
                        .padding(.top, 34).padding(.bottom, -24).offset(x: 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .refreshable { await onRefresh() }
            if status == .completed {
                if let downloadURL {
                    if download.activeURL == downloadURL {
                        ReviewDownloadProgressCard(receivedBytes: download.receivedBytes,
                                                   expectedBytes: download.expectedBytes)
                    } else if let file = download.savedFile(for: downloadURL) {
                        ShareLink("Buka hasil unduhan", item: file)
                            .padding(.top, 8)
                    } else {
                        Button("Unduh hasil peninjauan") { download.start(downloadURL) }
                            .disabled(download.activeURL != nil)
                            .padding(.top, 8)
                        if let message = download.errorMessage {
                            Text(message).font(.footnote).foregroundStyle(.secondary)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                PrimaryActionButton(title: downloadURL == nil ? "Lihat hasil peninjauan" : "Lihat & unduh hasil", systemImage: "document.fill",
                                    imagePlacement: .trailing) {
                    if let downloadURL, download.savedFile(for: downloadURL) == nil,
                       download.activeURL == nil {
                        download.start(downloadURL)
                    }
                    onViewResults()
                }
                    .padding(.horizontal, 24).padding(.vertical, 8)
            }
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
                        .fill(entry.isReached ? Color.primary : Color.secondary)
                        .frame(width: entry.isReached ? 20 : 12, height: entry.isReached ? 20 : 12)
                        .offset(y: entry.date == nil ? 7 : 24)
                }
                .frame(width: 20)
                .padding(.bottom, isLast ? 0 : -24)

            VStack(alignment: .leading, spacing: 4) {
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

struct ReviewDownloadProgressCard: View {
    let receivedBytes: Int64
    let expectedBytes: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Mengunduh hasil peninjauan").font(.headline)
                if expectedBytes > 0 {
                    HStack(spacing: 8) {
                        let fraction = min(1, Double(receivedBytes) / Double(expectedBytes))
                        ProgressView(value: fraction).tint(.primary)
                        Text(fraction.formatted(.percent.precision(.fractionLength(0))))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView()
                }
                Text(ByteCountFormatter.string(fromByteCount: receivedBytes, countStyle: .file)
                     + (expectedBytes > 0
                        ? " dari " + ByteCountFormatter.string(fromByteCount: expectedBytes, countStyle: .file)
                        : ""))
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 24))
            Text("Anda dapat keluar dari halaman ini. Setelah selesai diunduh, hasil peninjauan dapat dibuka tanpa sinyal internet.")
                .font(.footnote).foregroundStyle(.secondary)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16)
    }
}

#Preview("Unduhan laporan", traits: .sizeThatFitsLayout) {
    ReviewDownloadProgressCard(receivedBytes: 8_000_000, expectedBytes: 20_000_000)
        .padding(.vertical, 16)
        .frame(width: 402)
        .background(KropsTheme.background)
}
