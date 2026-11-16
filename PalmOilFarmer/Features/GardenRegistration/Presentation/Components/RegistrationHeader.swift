import SwiftUI

/// Isi kartu konfirmasi kalau tombol tutup header berupa glass menu.
struct RegistrationDiscardPrompt {
    let isPresented: Binding<Bool>
    let title: String
    let message: String
    let onDiscard: () -> Void
}

struct RegistrationHeader: View {
    var title = ""
    var isMapHeader = false
    var closeSymbol = "xmark"
    /// Matikan kalau tombol tutup digambar sendiri oleh layar (misalnya glass menu di peta).
    var showsCloseButton = true
    /// Diisi → tombol tutup menjadi glass menu "Buang". `onClose` tetap dipanggil saat X diketuk.
    var discardPrompt: RegistrationDiscardPrompt? = nil
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
                if let discardPrompt {
                    // Jejak tata letaknya tetap 44 × 44; kartu yang membesar meluber ke bawah header.
                    RegistrationDiscardMenu(isExpanded: discardPrompt.isPresented,
                                            title: discardPrompt.title, message: discardPrompt.message,
                                            onClose: onClose, onDiscard: discardPrompt.onDiscard)
                        .frame(width: RegistrationStyle.controlSize, height: RegistrationStyle.controlSize,
                               alignment: .topLeading)
                } else if showsCloseButton {
                    RegistrationIconButton(symbol: closeSymbol,
                                           label: closeSymbol == "xmark" ? "Tutup" : "Kembali",
                                           action: onClose)
                }
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
