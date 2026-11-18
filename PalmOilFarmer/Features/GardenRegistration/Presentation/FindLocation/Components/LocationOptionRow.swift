import SwiftUI

/// A selectable row for search results and alternative location sources.
struct LocationOptionRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Sketch "Molecule / List Row" corner radius.
    private static let cornerRadius: CGFloat = 20
    @ScaledMetric(relativeTo: .title3) private var iconSize = 36
    let title: String
    let subtitle: String
    let symbol: String
    var isLoading = false
    var isBrand = true
    let action: () -> Void

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
        Button(action: action) {
            layout {
                Image(systemName: symbol)
                    .font(.subheadline)
                    .foregroundStyle(isBrand ? KropsTheme.accentHero : KropsTheme.labelSecondary)
                    .frame(width: iconSize, height: iconSize)
                    .background(isBrand ? KropsTheme.accentSoft : KropsTheme.fillBlack8, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                if isLoading {
                    ProgressView()
                } else if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: "chevron.right").font(.subheadline.bold()).foregroundStyle(KropsTheme.labelTertiary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: Self.cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#if DEBUG
#Preview("Baris opsi lokasi") {
    VStack(spacing: 8) {
        LocationOptionRow(title: "SMKN 1 Gunung Kijang", subtitle: "Kawal, Gunung Kijang, Bintan",
                          symbol: "mappin", isBrand: false) {}
        LocationOptionRow(title: "Saya sedang di kebun",
                          subtitle: "Lokasi kebun diambil dari posisi Anda saat ini.",
                          symbol: "location.fill") {}
        LocationOptionRow(title: "Saya sedang di kebun", subtitle: "Mencari lokasi…",
                          symbol: "location.fill", isLoading: true) {}
        LocationOptionRow(title: "Saya punya foto kebun",
                          subtitle: "Lokasi kebun dicari dari foto yang diambil di sana.",
                          symbol: "photo.fill") {}
    }
    .padding(16)
    .background(KropsTheme.surfaceBackground)
}
#endif
