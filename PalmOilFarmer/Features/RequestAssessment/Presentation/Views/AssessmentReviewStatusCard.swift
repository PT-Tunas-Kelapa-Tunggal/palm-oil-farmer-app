import SwiftUI

struct AssessmentReviewStatusCard: View {
    enum Phase: Hashable {
        case inReview
        case ready
        case downloading
        case downloaded
    }

    enum Status {
        case inReview(contactName: String)
        case results(AssessmentResultsViewModel.State)
        case finished(completedAt: Date?, byteCount: Int64?)

        var phase: Phase {
            switch self {
            case .inReview: .inReview
            case .results(.ready): .ready
            case .results(.downloading): .downloading
            case .results(.downloaded): .downloaded
            case .finished: .downloaded
            }
        }
    }

    let status: Status
    var completedAt: Date? = nil
    var expectedByteCount: Int64? = nil
    let onAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .body) private var buttonHeight = 52.0
    @State private var hasRevealedCheckmark = false

    private var dark: Bool { colorScheme == .dark }
    private var palette: AssessmentPalette { .init(isDark: dark) }

    var body: some View {
        AssessmentGardenStatusCard {
            badge

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(description)
                    .font(.body)
                    .foregroundStyle(palette.secondary)
            }
            .id(status.phase)
            .transition(.opacity)

            switch status {
            case .inReview:
                EmptyView()
            case .results(.ready):
                metadata(prefix: "Selesai", date: completedAt, bytes: expectedByteCount)
                    .transition(.opacity)
            case .results(.downloading(let progress)):
                downloadProgress(progress)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            case .results(.downloaded(let receipt)):
                metadata(prefix: "Diunduh", date: receipt.downloadedAt, bytes: receipt.byteCount)
                    .transition(.opacity)
            case .finished(let completedAt, let byteCount):
                metadata(prefix: "Diunduh", date: completedAt, bytes: byteCount)
                    .transition(.opacity)
            }
        } actions: {
            switch status.phase {
            case .inReview:
                Button(action: onAction) {
                    Text("Lihat Status Peninjauan")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: buttonHeight)
                }
                .buttonStyle(.plain)
                .foregroundStyle(palette.buttonLabel)
                .glassEffect(.regular.tint(palette.buttonTint).interactive(), in: Capsule())
            case .ready:
                primaryButton("Unduh Hasil Peninjauan", enabled: true)
            case .downloading:
                Button(action: onAction) { buttonLabel("Batalkan Unduhan") }
                    .buttonStyle(.plain)
                    .foregroundStyle(dark ? palette.primary : palette.accent)
            case .downloaded:
                primaryButton("Lihat Hasil Peninjauan", enabled: true)
            }
        }
    }

    private var badge: some View {
        let drawsCheckmark = status.phase == .inReview && !reduceMotion
        return Image(.assessmentInReviewIllustration)
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .overlay {
                if !drawsCheckmark || hasRevealedCheckmark {
                    Image(systemName: symbol)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
                        .symbolEffect(.bounce.down, options: .repeat(.periodic(delay: 0.9)),
                                      isActive: !reduceMotion && scenePhase == .active && status.phase == .downloading)
                        .transition(drawsCheckmark
                                    ? AnyTransition(SymbolEffectTransition.symbolEffect(.drawOn))
                                    : .identity)
                }
            }
            .accessibilityHidden(true)
            .task(id: status.phase) {
                guard status.phase == .inReview, !hasRevealedCheckmark else { return }
                if reduceMotion {
                    hasRevealedCheckmark = true
                    return
                }
                do {
                    try await Task.sleep(for: .milliseconds(100))
                    withAnimation { hasRevealedCheckmark = true }
                } catch {
                    // The card disappeared or advanced before the checkmark appeared.
                }
            }
    }

    private var title: LocalizedStringKey {
        switch status.phase {
        case .inReview: "Pengajuan Terkirim"
        case .ready: "Peninjauan Selesai"
        case .downloading: "Mengunduh Hasil Peninjauan"
        case .downloaded: "Hasil Peninjauan Siap Dilihat"
        }
    }

    private var description: LocalizedStringKey {
        switch status {
        case .inReview(let contactName):
            "Petugas akan menghubungi \(contactName) dalam 1 hari kerja untuk menentukan jadwal kunjungan ke kebun."
        case .results(.ready):
            "Hasil peninjauan sudah tersedia. Unduh agar peta kebun dan rekomendasi pupuk bisa dibuka tanpa sinyal."
        case .results(.downloading):
            "Biarkan aplikasi tetap terbuka sampai unduhan selesai."
        case .results(.downloaded(let receipt)):
            receipt.localFileURL == nil
                ? "Simulasi unduhan selesai. Peta kebun dan rekomendasi pupuk asli belum tersedia."
                : "Peta kebun dan rekomendasi pupuk sudah tersimpan di ponsel Anda dan bisa dibuka tanpa sinyal."
        case .finished:
            "Peta kebun dan rekomendasi pupuk sudah tersimpan di ponsel Anda dan bisa dibuka tanpa sinyal."
        }
    }

    private var symbol: String {
        switch status.phase {
        case .inReview: "checkmark"
        case .ready: "checkmark.seal.fill"
        case .downloading: "arrow.down"
        case .downloaded: "checkmark"
        }
    }

    @ViewBuilder
    private func metadata(prefix: String, date: Date?, bytes: Int64?) -> some View {
        let timestamp = date.map { "\(prefix) \(Self.dateFormatter.string(from: $0))" }
        let size = bytes.map(sizeLabel)
        let parts = [timestamp, size].compactMap { $0 }
        if let timestamp, let size, !dark {
            Text("\(timestamp) (\(size))")
                .font(.footnote)
                .foregroundStyle(palette.secondary)
        } else if !parts.isEmpty {
            Text(parts.joined(separator: " · "))
                .font(.footnote)
                .foregroundStyle(palette.secondary)
        }
    }

    private func downloadProgress(_ progress: AssessmentDownloadProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if !dark, let fraction = progress.fraction {
                    GeometryReader { geometry in
                        Capsule()
                            .fill(palette.background)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(palette.accent)
                                    .frame(width: geometry.size.width * fraction)
                            }
                    }
                    .frame(height: 6)
                    .accessibilityElement()
                    .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
                } else {
                    ProgressView(value: progress.fraction)
                        .tint(palette.accent)
                }
            }
            .accessibilityLabel("Progres unduhan hasil peninjauan")
            .animation(reduceMotion ? nil : .linear(duration: 0.2), value: progress.fraction)

            ViewThatFits(in: .horizontal) {
                HStack {
                    progressLabel(progress).fixedSize()
                    Spacer(minLength: 8)
                    remainingLabel(progress).fixedSize()
                }
                VStack(alignment: .leading, spacing: 4) {
                    progressLabel(progress)
                    remainingLabel(progress)
                }
            }
            .font(.footnote)
            .monospacedDigit()
        }
    }

    private func progressLabel(_ progress: AssessmentDownloadProgress) -> Text {
        if let total = progress.totalBytes, let fraction = progress.fraction {
            let received = sizeLabel(progress.receivedBytes)
            let size = sizeLabel(total)
            if dark {
                return Text("\(received) dari \(size) · \(fraction, format: .percent.precision(.fractionLength(0)))")
            }
            return Text("\(received) dari \(size) (\(fraction, format: .percent.precision(.fractionLength(0))))")
        }
        return Text(sizeLabel(progress.receivedBytes))
    }

    private func remainingLabel(_ progress: AssessmentDownloadProgress) -> Text {
        guard let remaining = progress.secondsRemaining else { return Text("Memulai unduhan") }
        let seconds = Int(remaining.rounded(.up))
        if seconds <= 0 { return Text("Selesai") }
        if seconds >= 60 { return Text("Sekitar \((seconds + 59) / 60) menit lagi") }
        return Text("Sekitar \(seconds) detik lagi")
    }

    private func sizeLabel(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func primaryButton(_ title: LocalizedStringKey, enabled: Bool) -> some View {
        Button(action: onAction) { buttonLabel(title) }
            .buttonStyle(.plain)
            .foregroundStyle(palette.buttonLabel)
            .glassEffect(.regular.tint(palette.buttonTint), in: Capsule())
            .disabled(!enabled)
    }

    private func buttonLabel(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: buttonHeight)
            .contentShape(Rectangle())
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.timeZone = TimeZone(identifier: "Asia/Jakarta")
        formatter.dateFormat = "d MMMM yyyy, HH.mm 'WIB'"
        return formatter
    }()
}

#Preview("Detail Kebun · Ready to Download") {
    AssessmentReviewStatusCard(status: .results(.ready), completedAt: .now, expectedByteCount: 20_000_000, onAction: {})
        .padding(16)
        .preferredColorScheme(.dark)
}

#Preview("Detail Kebun · Downloading · Light") {
    AssessmentReviewStatusCard(
        status: .results(.downloading(.init(receivedBytes: 8_000_000, totalBytes: 20_000_000, secondsRemaining: 60))),
        completedAt: .now, expectedByteCount: 20_000_000, onAction: {}
    )
    .padding(16)
    .background(AssessmentPalette.lightBackground)
    .preferredColorScheme(.light)
}

#Preview("Detail Kebun · Downloaded") {
    AssessmentReviewStatusCard(
        status: .results(.downloaded(.init(downloadedAt: .now, byteCount: 20_000_000, localFileURL: nil))),
        completedAt: .now, expectedByteCount: 20_000_000, onAction: {}
    )
    .padding(16)
    .preferredColorScheme(.dark)
}
