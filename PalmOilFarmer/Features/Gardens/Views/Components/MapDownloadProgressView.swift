import SwiftUI

struct MapDownloadProgressView: View {
    let state: MapDownloadState
    var usesCardBackground = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch state {
            case let .downloading(progress, received, total, remaining):
                Text("Sedang mengunduh peta").font(.headline)
                let fraction = progress.isFinite ? min(max(progress, 0), 1) : 0
                HStack(spacing: 8) {
                    ProgressView(value: fraction)
                        .tint(.secondary)
                        .accessibilityLabel("Unduhan peta")
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                }
                HStack {
                    Text("\(received) MB dari \(total) MB")
                    Spacer()
                    Text(remaining)
                }
                .font(.footnote).foregroundStyle(.secondary)
            case .completed:
                Image(systemName: "checkmark.icloud.fill").font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Peta berhasil diunduh").font(.headline)
                    Text("Peta kini dapat dibuka di kebun tanpa sinyal internet.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            case .failed(let message):
                Label("Peta belum terunduh", systemImage: "exclamationmark.icloud")
                    .font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, usesCardBackground ? 16 : 8)
        .background(usesCardBackground ? KropsTheme.tertiaryFill : .clear, in: RoundedRectangle(cornerRadius: 24))
    }
}
