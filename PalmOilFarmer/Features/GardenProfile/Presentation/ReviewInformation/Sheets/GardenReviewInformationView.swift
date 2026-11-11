import SwiftUI

/// "Peninjauan Kebun" sheet: three-step explanation before applying for a review.
struct GardenReviewInformationView: View {
    @AppStorage("gardenReview.hideIntroduction") private var hideIntroduction = false
    let onClose: () -> Void
    let onApply: () -> Void

    var body: some View {
        DynamicSheet(animation: .bouncy, size: .large) {
            sheetContent
        }
        .presentationBackgroundInteraction(.disabled)
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
    }

    @ViewBuilder
    private var sheetContent: some View {
        VStack(spacing: 0) {
            GardenProfileHeader(title: "Peninjauan Kebun", symbol: "xmark", onBack: onClose)
                .padding(.top, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    explanation(1, title: "Petugas memotret kebun dengan drone", image: "ProfileReviewDrone",
                        message: "Petugas datang sesuai jadwal yang Anda sepakati, lalu menerbangkan drone untuk memotret seluruh kebun dari udara.")
                    explanation(2, title: "Setiap pohon diperiksa dari foto", image: "ProfileReviewAnalysis",
                        message: "Foto udara diolah untuk melihat tingkat kehijauan daun, sehingga terlihat pohon yang sehat dan pohon yang perlu perhatian.")
                    explanation(3, title: "Anda menerima rekomendasi pupuk per area", image: "ProfileReviewRecommendation",
                        message: "Hasilnya berupa peta kebun dan dosis pupuk untuk setiap area, supaya pupuk tepat sasaran dan tidak terbuang.")
                    VStack(spacing: 4) {
                        Button { hideIntroduction.toggle() } label: {
                            HStack(spacing: 14) {
                                Image(systemName: hideIntroduction ? "checkmark.circle.fill" : "circle")
                                    .font(.title2).foregroundStyle(hideIntroduction ? GardenProfileStyle.accent : Color(uiColor: .tertiaryLabel))
                                Text("Jangan tampilkan lagi").font(.subheadline)
                                Spacer()
                            }.padding(.horizontal, 10).frame(minHeight: 44)
                        }.buttonStyle(.plain)
                            .accessibilityValue(hideIntroduction ? "Dipilih" : "Tidak dipilih")
                        GardenProfileActionButton(title: "Lanjutkan Pengajuan", action: onApply)
                    }
                }
                .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 34)
            }
        }
        .background(GardenProfileStyle.card)
    }

    private func explanation(_ step: Int, title: String, image: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(image).resizable().aspectRatio(354.0 / 150.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("Langkah \(step)").font(.footnote.weight(.semibold)).foregroundStyle(GardenProfileStyle.accent)
                Text(title).font(.body.weight(.semibold))
                Text(message).font(.body).foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG
#Preview("Informasi peninjauan") {
    GardenReviewInformationView(onClose: {}, onApply: {})
}
#Preview("Sheet Peninjauan Kebun") {
    SheetPreview(backdrop: "ProfileHiFiMap") {
        GardenReviewInformationView(onClose: {}, onApply: {})
    }
}
#endif
