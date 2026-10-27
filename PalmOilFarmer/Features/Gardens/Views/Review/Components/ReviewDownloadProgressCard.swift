import SwiftUI

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
