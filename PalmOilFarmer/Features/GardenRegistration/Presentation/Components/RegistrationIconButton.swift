import SwiftUI

struct RegistrationIconButton: View {
    let symbol: String
    let label: String
    var isProminent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .frame(width: RegistrationStyle.controlSize, height: RegistrationStyle.controlSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isProminent ? KropsTheme.labelInversePrimary : .primary)
        .background {
            if isProminent { Circle().fill(KropsTheme.surfaceInverse) }
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(label)
    }
}

/// Tombol X yang membesar menjadi kartu konfirmasi "Buang" bergaya dialog iOS (glass menu).
/// Dipakai di header peta batas kebun dan sheet Data Kebun, jadi ukurannya selalu sama.
/// Ukuran kartu mengikuti Sketch: KROPS › ☀️ HI-FID › "Konfirmasi Hapus" (260 × 166).
struct RegistrationDiscardMenu: View {
    /// Gaya saat tertutup mengikuti latar tempat tombol berada (gelap di peta, sistem di sheet).
    @Environment(\.colorScheme) private var closedColorScheme
    @Binding var isExpanded: Bool
    let title: String
    let message: String
    var discardTitle = "Buang"
    /// Ketukan X. Pemanggil yang memutuskan: langsung tutup, atau buka kartu lewat `isExpanded`.
    let onClose: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        ExpandableGlassMenu(
            alignment: .topLeading,
            progress: isExpanded ? 1 : 0,
            labelSize: CGSize(width: RegistrationStyle.controlSize, height: RegistrationStyle.controlSize),
            // Saat tertutup radius otomatis dibatasi setengah ukuran → tetap lingkaran.
            cornerRadius: 34
        ) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 12, trailing: 8))

                Button(role: .destructive, action: onDiscard) {
                    Text(discardTitle)
                        .font(.body)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .foregroundStyle(KropsTheme.statusCritical)
                .background(KropsTheme.fillBlack8, in: .capsule)
            }
            .padding(14)
            .frame(width: 260, alignment: .leading)
        } label: {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 22))
                    .frame(width: RegistrationStyle.controlSize, height: RegistrationStyle.controlSize)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup")
        }
        // Terbuka: kaca terang seperti dialog iOS. Tertutup: ikut gaya latarnya.
        .environment(\.colorScheme, isExpanded ? .light : closedColorScheme)
        .animation(.glassMenu, value: isExpanded)
    }
}

#if DEBUG
#Preview("Tombol ikon", traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        RegistrationIconButton(symbol: "xmark", label: "Tutup") {}
        RegistrationIconButton(symbol: "chevron.left", label: "Kembali") {}
        RegistrationIconButton(symbol: "location.fill", label: "Lokasi saya") {}
        RegistrationIconButton(symbol: "checkmark", label: "Selesai", isProminent: true) {}
    }
    .padding(24)
    .background(KropsTheme.surfaceBackground)
}
#endif
