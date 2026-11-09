import SwiftUI

struct GardenProfileHeader: View {
    var title = "Profil Kebun"
    var symbol = "chevron.left"
    var onEdit: (() -> Void)? = nil
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Text(title).font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 84)
                .accessibilityAddTraits(.isHeader)
            HStack {
                GardenProfileIconButton(symbol: symbol, label: symbol == "xmark" ? "Tutup" : "Kembali", action: onBack)
                Spacer()
                if let onEdit {
                    Button(action: onEdit) { Text("Ubah").font(.body).frame(width: 67, height: 44) }
                        .buttonStyle(.plain).glassEffect(.regular.interactive(), in: Capsule())
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(minHeight: 44)
    }
}

#if DEBUG
#Preview("Header · Ubah profil", traits: .sizeThatFitsLayout) {
    GardenProfileHeader(onEdit: {}, onBack: {}).frame(width: 402)
}
#endif
