import SwiftUI

struct GardenProfileCompletionCard: View {
    let onComplete: () -> Void
    @ScaledMetric(relativeTo: .title2) private var iconSize = 44
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Lengkapi profil kebun").font(.title2.bold())
                Text("Isi riwayat pemupukan dan panen agar hasil peninjauan lebih sesuai dengan kondisi kebun Anda.")
            }
            explanation("Riwayat Pemupukan", message: "Data ini menjadi pembanding antara pupuk yang sudah diberikan dan kebutuhan kebun.", symbol: "leaf")
            explanation("Riwayat Panen", message: "Data ini membantu memperkirakan kebutuhan kebun dari hasil yang sudah didapat.", symbol: "basket")
            GardenProfileActionButton(title: "Lengkapi sekarang", action: onComplete).padding(.top, 8)
        }
        .font(.body).padding(24)
        .background(GardenProfileStyle.card, in: RoundedRectangle(cornerRadius: 28))
    }

    private func explanation(_ title: String, message: String, symbol: String) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            Image(systemName: symbol).font(.title2)
                .frame(width: iconSize, height: iconSize)
                .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).fontWeight(.semibold)
                Text(message)
            }
        }
    }
}

#if DEBUG
#Preview("Kelengkapan profil", traits: .sizeThatFitsLayout) {
    GardenProfileCompletionCard(onComplete: {}).padding().frame(width: 402)
}
#Preview("Kelengkapan profil · Teks besar", traits: .sizeThatFitsLayout) {
    GardenProfileCompletionCard(onComplete: {}).padding().frame(width: 320)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
