import SwiftUI

/// The location guide and search share one sheet and one registration session.
struct RegistrationIntroView: View {
    @State private var flow: GardenRegistrationFlow
    @Environment(\.dismiss) private var dismiss
    typealias Step = GardenRegistrationStep

    init(flow: GardenRegistrationFlow) {
        _flow = State(initialValue: flow)
    }

    var body: some View {
        Group {
            switch flow.coordinator.step {
            case .guide:
                LocationDiscoveryGuide(onContinue: flow.coordinator.continueToSearch) {
                    flow.coordinator.cancel()
                    dismiss()
                }
            case .search:
                LocationSearchView(flow: flow)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(RegistrationStyle.background)
        .presentationBackgroundInteraction(.disabled)
    }
}

struct LocationDiscoveryGuide: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title2) private var iconSize = 44
    let onContinue: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RegistrationHeader(onClose: onClose)
            ScrollView {
                VStack(spacing: 16) {
                    Text("Temukan Lokasi Kebun")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Image("LocationGuideSatellite")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 184)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius))
                        .padding(.horizontal, 30)
                        .accessibilityHidden(true)
                    VStack(spacing: 0) {
                        guideRow("Gunakan lokasi saat ini",
                                 message: "Jika sedang berada di kebun, peta langsung menampilkan posisi Anda.",
                                 symbol: "location")
                        guideRow("Cari patokan terdekat",
                                 message: "Ketik nama desa, masjid, sekolah, atau simpang jalan di dekat kebun.",
                                 symbol: "mappin.and.ellipse")
                        guideRow("Unggah foto terdekat",
                                 message: "Lokasi kebun ditemukan dari foto yang pernah diambil di sana.",
                                 symbol: "photo")
                    }
                    .padding(.horizontal, 30)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(RegistrationStyle.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RegistrationPrimaryButton(title: "Cari lokasi kebun", action: onContinue)
                .padding(.horizontal, 34)
                .padding(.top, 24)
                .padding(.bottom, 2)
                .background { BottomBlurFade() }
        }
    }

    private func guideRow(_ title: String, message: String, symbol: String) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 20))
        return layout {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: iconSize, height: iconSize)
                .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.title3.weight(.semibold))
                Text(message).font(.body)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
            .padding(.bottom, 16)
            .padding(.trailing, 20)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("COdedUI5 · Temukan Lokasi Kebun") {
    RegistrationIntroView(onLocate: { _ in })
}

#if DEBUG
#Preview("COdedUI5 · Cari Alamat") {
    RegistrationIntroView(initialStep: .search, onLocate: { _ in })
}
#endif
