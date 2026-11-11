import SwiftUI

/// Content of the "Cari Lokasi" sheet, step `.guide`: explains the three ways to find a garden.
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

#if DEBUG
#Preview("Panduan Temukan Lokasi") {
    LocationDiscoveryGuide(onContinue: {}, onClose: {})
}

#Preview("Panduan Temukan Lokasi · Teks besar") {
    LocationDiscoveryGuide(onContinue: {}, onClose: {})
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
