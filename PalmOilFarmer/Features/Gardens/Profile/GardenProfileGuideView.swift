import SwiftUI

struct GardenProfileGuideView: View {
    var isReadyForReview = false
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: isReadyForReview ? .center : .leading, spacing: 16) {
            Text(isReadyForReview ? "Kebun Siap Ditinjau" : "Lengkapi profil kebun")
                .font(.title.bold())
            if isReadyForReview {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 100))
                    .padding(.vertical, 32)
                    .accessibilityHidden(true)
                Text("Pastikan titik yang ditampilkan di peta adalah lokasi kebun Anda.")
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
            } else {
                Text("Isi riwayat pemupukan dan panen agar hasil peninjauan lebih sesuai dengan kondisi kebun Anda.")
                explanation("Riwayat Pemupukan",
                            message: "Data ini menjadi pembanding antara pupuk yang sudah diberikan dan kebutuhan kebun.")
                explanation("Riwayat Panen",
                            message: "Data ini membantu memperkirakan kebutuhan kebun dari hasil yang sudah didapat.")
            }
            GardenFlowActionButton(
                title: isReadyForReview ? "Ajukan" : "Lengkapi sekarang",
                systemImage: isReadyForReview ? "paperplane.fill" : nil,
                action: onContinue
            )
            .padding(.top, 16)
            Button("Lakukan nanti") { dismiss() }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(24)
        .fittedSheetHeight()
        .presentationDragIndicator(.hidden)
        .presentationBackground(GardenFlowStyle.background)
    }

    private func explanation(_ title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(message).fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Lengkapi profil") {
    GardenProfileGuideView(onContinue: {})
}

#Preview("Siap ditinjau") {
    GardenProfileGuideView(isReadyForReview: true, onContinue: {})
}
