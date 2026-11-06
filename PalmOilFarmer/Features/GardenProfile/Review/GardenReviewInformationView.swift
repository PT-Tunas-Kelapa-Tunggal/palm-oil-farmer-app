import SwiftUI

struct GardenReviewInformationView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var illustrationSize = 52
    let onClose: () -> Void
    let onApply: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            GardenProfileHeader(title: "Peninjauan Kebun", symbol: "xmark", onBack: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    explanation("Kenali kebutuhan setiap bagian kebun", symbol: "leaf.fill",
                                message: "Petugas memeriksa kondisi tanaman di seluruh kebun Anda. Dari pemeriksaan ini, Anda dapat mengetahui bagian kebun yang sehat dan bagian yang perlu diperhatikan.")
                    explanation("Pengambilan gambar dengan drone", symbol: "drone.fill",
                                message: "Petugas datang sesuai jadwal yang disepakati dan mengambil gambar kebun dari udara. Gambar tersebut diolah untuk melihat tingkat kehijauan daun di setiap area.")
                    explanation("Rekomendasi pupuk per area", symbol: "chart.line.uptrend.xyaxis",
                                message: "Anda akan menerima peta kondisi kebun beserta dosis pupuk yang sesuai untuk setiap area. Pemupukan menjadi lebih tepat sehingga pupuk tidak terbuang.")
                    GardenProfileActionButton(title: "Ajukan Peninjauan", symbol: "paperplane.fill", action: onApply)
                }
                .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 32)
            }
        }
        .background(GardenProfileStyle.formBackground)
        .presentationDetents([.large]).presentationDragIndicator(.hidden)
    }

    private func explanation(_ title: String, symbol: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: symbol).font(.system(size: illustrationSize)).frame(minHeight: 88).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.body.weight(.semibold))
                Text(message).font(.body)
            }
        }
    }
}

#if DEBUG
#Preview("Informasi peninjauan") {
    GardenReviewInformationView(onClose: {}, onApply: {})
}
#endif
