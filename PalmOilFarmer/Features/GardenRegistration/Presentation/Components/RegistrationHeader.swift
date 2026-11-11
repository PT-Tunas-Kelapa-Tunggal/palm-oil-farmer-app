import SwiftUI

struct RegistrationHeader: View {
    var title = ""
    var isMapHeader = false
    var closeSymbol = "xmark"
    var trailingSymbol: String? = nil
    var trailingLabel = ""
    var isTrailingEnabled = true
    var onTrailing: (() -> Void)? = nil
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 72)
                .padding(.vertical, isMapHeader ? 10 : 20)
                .accessibilityAddTraits(.isHeader)
            HStack {
                RegistrationIconButton(symbol: closeSymbol,
                                       label: closeSymbol == "xmark" ? "Tutup" : "Kembali",
                                       action: onClose)
                Spacer(minLength: 0)
                if let trailingSymbol, let onTrailing {
                    RegistrationIconButton(symbol: trailingSymbol, label: trailingLabel,
                                           isProminent: trailingSymbol == "checkmark", action: onTrailing)
                        .disabled(!isTrailingEnabled)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isMapHeader ? 0 : 12)
        }
        .frame(minHeight: isMapHeader ? 44 : 70)
    }
}

#if DEBUG
#Preview("Header registrasi", traits: .sizeThatFitsLayout) {
    VStack(spacing: 0) {
        RegistrationHeader(title: "Cari Lokasi Kebun", onClose: {})
        Divider()
        RegistrationHeader(title: "Tahun Tanam", closeSymbol: "chevron.left",
                           trailingSymbol: "checkmark", trailingLabel: "Selesai",
                           onTrailing: {}, onClose: {})
        Divider()
        RegistrationHeader(title: "Buat Batas Kebun", isMapHeader: true, onClose: {})
            .padding(.vertical, 8)
            .background(.black.opacity(0.7))
            .environment(\.colorScheme, .dark)
    }
    .frame(width: 402)
    .background(RegistrationStyle.background)
}
#endif
