import SwiftUI

struct ReviewStatusScreen: View {
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

#Preview("Status · Submitted") {
    ReviewStatusScreen(gardenName: "Belakang Rumah", status: .submitted,
                     entries: ReviewTimelineEntry.referenceEntries(for: .submitted), onViewResults: {})
}
#Preview("Status · Scheduled") {
    ReviewStatusScreen(gardenName: "Belakang Rumah", status: .scheduled,
                     entries: ReviewTimelineEntry.referenceEntries(for: .scheduled), onViewResults: {})
}
#Preview("Status · In Review") {
    ReviewStatusScreen(gardenName: "Belakang Rumah", status: .inReview,
                     entries: ReviewTimelineEntry.referenceEntries(for: .inReview), onViewResults: {})
}
#Preview("Status · Completed") {
    ReviewStatusScreen(gardenName: "Belakang Rumah", status: .completed,
                     entries: ReviewTimelineEntry.referenceEntries(for: .completed), onViewResults: {})
}
#Preview("Timeline Row", traits: .sizeThatFitsLayout) {
    ReviewTimelineRow(entry: ReviewTimelineEntry.referenceEntries(for: .submitted)[0])
        .padding(24).frame(width: 402)
}

#Preview("Unduhan laporan", traits: .sizeThatFitsLayout) {
    ReviewDownloadProgressCard(receivedBytes: 8_000_000, expectedBytes: 20_000_000)
        .padding(.vertical, 16)
        .frame(width: 402)
        .background(KropsTheme.background)
}
