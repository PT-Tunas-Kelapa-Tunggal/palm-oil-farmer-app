import SwiftUI

struct GardenProfileHeader: View {
    var title = "Profil Kebun"
    var symbol = "chevron.left"
    var onEdit: (() -> Void)? = nil
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title).font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 72).padding(.vertical, 22)
                .accessibilityAddTraits(.isHeader)
            HStack {
                GardenProfileIconButton(symbol: symbol, label: symbol == "xmark" ? "Tutup" : "Kembali", action: onBack)
                Spacer()
                if let onEdit { GardenProfileIconButton(symbol: "pencil", label: "Ubah profil kebun", action: onEdit) }
            }
            .padding(.horizontal, 12)
        }
        .frame(minHeight: 72)
    }
}

#if DEBUG
#Preview("Header · Ubah profil", traits: .sizeThatFitsLayout) {
    GardenProfileHeader(onEdit: {}, onBack: {}).frame(width: 402)
}
#endif
