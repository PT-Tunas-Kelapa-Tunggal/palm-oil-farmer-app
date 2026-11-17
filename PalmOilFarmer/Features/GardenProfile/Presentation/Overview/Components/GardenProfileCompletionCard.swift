import SwiftUI

struct GardenProfileCompletionCard: View {
    let onComplete: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Lengkapi profil kebun").font(.title2.bold())
                Text("Isi riwayat panen dan pemupukan agar hasil peninjauan lebih sesuai dengan kebun Anda.").foregroundStyle(.secondary)
            }
            explanation("Riwayat Panen", message: "Membantu memperkirakan kebutuhan kebun dari hasil panen yang sudah didapat.", symbol: "chart.xyaxis.line")
            explanation("Riwayat Pemupukan", message: "Menjadi pembanding antara pupuk yang sudah diberikan dan kebutuhan kebun.", symbol: "leaf")
            GardenProfileActionButton(title: "Lengkapi Profil Kebun", action: onComplete)
        }
        .font(.body).padding(20)
        .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 24))
    }

    private func explanation(_ title: String, message: String, symbol: String) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return layout {
            Image(systemName: symbol).font(.title2)
                .foregroundStyle(KropsTheme.accentHero)
                .frame(width: 36, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).fontWeight(.semibold)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
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
