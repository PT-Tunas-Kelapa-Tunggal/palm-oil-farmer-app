import SwiftUI

struct GardenProfileActionButton: View {
    let title: String
    var symbol: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 5) {
                    Text(title)
                    if let symbol { Image(systemName: symbol) }
                }
                Text(title)
            }
            .font(.body.weight(.semibold)).multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 22)
        }
        .buttonStyle(.glassProminent).buttonBorderShape(.capsule)
        .controlSize(.large).tint(KropsTheme.surfaceInverse)
    }
}

#if DEBUG
#Preview("Aksi · Simpan dan ajukan", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        GardenProfileActionButton(title: "Simpan", action: {})
        GardenProfileActionButton(title: "Ajukan Peninjauan", symbol: "paperplane.fill", action: {})
    }.padding().frame(width: 402)
}
#endif
