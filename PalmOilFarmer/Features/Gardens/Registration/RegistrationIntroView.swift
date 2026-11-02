import SwiftUI

/// Location guidance and search share one sheet; boundary guidance is shown on the map.
struct RegistrationIntroView: View {
    let onLocate: (GardenLocation) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step

    enum Step {
        case guide, search
    }

    init(initialStep: Step = .guide, onLocate: @escaping (GardenLocation) -> Void) {
        self.onLocate = onLocate
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        Group {
            switch step {
            case .guide:
                guide.presentationDetents([.large])
            case .search:
                LocationSearchView(onSelect: onLocate).presentationDetents([.large])
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground(GardenFlowStyle.background)
        .presentationBackgroundInteraction(.disabled)
    }

    private var guide: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "", onClose: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Temukan Lokasi Kebun")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                    Image("CodedUI3LocationGuide")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 185)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .accessibilityHidden(true)
                    guideSection("Gunakan lokasi saat ini",
                                 message: "Jika sedang berada di kebun, peta langsung menampilkan posisi Anda.")
                    guideSection("Cari patokan terdekat",
                                 message: "Ketik nama desa, masjid, sekolah, atau simpang jalan di dekat kebun.")
                    guideSection("Unggah foto terdekat",
                                 message: "Lokasi kebun ditemukan dari foto yang pernah diambil di sana.")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            GardenFlowActionButton(title: "Cari lokasi kebun") {
                withAnimation { step = .search }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
    }

    private func guideSection(_ title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title3.weight(.semibold))
            Text(message).fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("CodedUI3 · Panduan Temukan Lokasi") {
    RegistrationIntroView(onLocate: { _ in })
}

#if DEBUG
#Preview("03 · Cari Alamat") {
    RegistrationIntroView(initialStep: .search, onLocate: { _ in })
}
#endif
