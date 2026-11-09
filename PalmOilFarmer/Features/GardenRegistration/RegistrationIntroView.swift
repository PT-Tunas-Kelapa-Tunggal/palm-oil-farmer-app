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
        .presentationDragIndicator(.visible)
        .presentationBackground(RegistrationStyle.background)
        .presentationBackgroundInteraction(.disabled)
    }
}

struct LocationDiscoveryGuide: View {
    let onContinue: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RegistrationHeader(onClose: onClose)
            ScrollView {
                VStack(spacing: 32) {
                    Image("LocationGuideSatellite")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .accessibilityHidden(true)
                    VStack(spacing: 12) {
                        Text("Temukan Lokasi Kebun")
                            .font(.title.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text("Ada tiga cara untuk menemukan kebun Anda di peta.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    VStack(spacing: 20) {
                        guideRow("Cari patokan terdekat",
                                 message: "Ketik nama desa, masjid, sekolah, atau simpang jalan di dekat kebun.",
                                 symbol: "mappin.and.ellipse")
                        guideRow("Gunakan lokasi saat ini",
                                 message: "Jika sedang berada di kebun, peta langsung menampilkan posisi Anda.",
                                 symbol: "location")
                        guideRow("Pakai foto dari kebun",
                                 message: "Lokasi kebun ditemukan dari foto yang pernah diambil di sana.",
                                 symbol: "photo")
                    }
                }
                .padding(.horizontal, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(RegistrationStyle.surface)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RegistrationPrimaryButton(title: "Cari Lokasi Kebun", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 2)
                .background { BottomBlurFade() }
        }
    }

    private func guideRow(_ title: String, message: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(RegistrationStyle.actionTint)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
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
