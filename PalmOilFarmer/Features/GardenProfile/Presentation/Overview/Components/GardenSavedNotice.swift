import SwiftUI

/// "✦ Profil kebun baru saja disimpan" line shown after a save.
/// The icon uses `accentHero`; the small text uses `accentPrimary` for contrast.
struct GardenSavedNotice: View {
    let text: String

    var body: some View {
        Label {
            Text(text).foregroundStyle(KropsTheme.accentPrimary)
        } icon: {
            Image(systemName: "sparkles").foregroundStyle(KropsTheme.accentHero)
        }
        .font(.caption.bold())
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview("Notifikasi simpan", traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: 12) {
        GardenSavedNotice(text: "Profil kebun baru saja disimpan")
        GardenSavedNotice(text: "Profil kebun baru saja diperbarui")
        GardenSavedNotice(text: "Data kebun baru saja diperbarui")
    }
    .padding()
}
#endif
