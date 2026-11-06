import SwiftUI

struct GardenProfileIconButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 22))
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain).glassEffect(.regular.interactive(), in: Circle())
        .foregroundStyle(.primary)
        .accessibilityLabel(label)
    }
}

#if DEBUG
#Preview("Tombol · Kembali dan tutup", traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        GardenProfileIconButton(symbol: "chevron.left", label: "Kembali", action: {})
        GardenProfileIconButton(symbol: "xmark", label: "Tutup", action: {})
    }.padding()
}
#endif
