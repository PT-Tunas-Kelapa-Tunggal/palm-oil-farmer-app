import SwiftUI

/// One header for every screen and sheet, so back, close, and confirm buttons are always 44 pt.
struct ScreenHeader: View {
    private let buttonSize: CGFloat = 44

    let title: String
    var systemImage = "xmark"
    var subtitle: String? = nil
    var height: CGFloat = 68
    var confirmationAction: (() -> Void)? = nil
    let onClose: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, buttonSize + 24)
            .padding(.vertical, 12)

            HStack {
                Button(action: onClose) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .frame(minWidth: buttonSize, minHeight: buttonSize)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel(systemImage == "xmark" ? "Tutup" : "Kembali")
                Spacer()
                if let confirmationAction {
                    Button(action: confirmationAction) {
                        Image(systemName: "checkmark")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(minWidth: buttonSize, minHeight: buttonSize)
                            .background(.black, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .accessibilityLabel("Simpan")
                }
            }
            .padding(12)
        }
        .frame(minHeight: height)
    }
}

#Preview("Header · Detail Kebun", traits: .sizeThatFitsLayout) {
    ScreenHeader(title: "Detail Kebun", systemImage: "chevron.left", onClose: {})
        .frame(width: 402)
}
#Preview("Header · Formulir", traits: .sizeThatFitsLayout) {
    ScreenHeader(title: "Riwayat Pemupukan", confirmationAction: {}, onClose: {})
        .frame(width: 402)
}
