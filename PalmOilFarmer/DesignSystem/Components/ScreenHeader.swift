import SwiftUI

struct ScreenHeader: View {
    let title: String
    var systemImage = "xmark"
    var subtitle: String? = nil
    var buttonSize: CGFloat = 48
    var height: CGFloat = 72
    var confirmationAction: (() -> Void)? = nil
    var onTitleLongPress: (() -> Void)? = nil
    var closeConfirmation: ScreenCloseConfirmation? = nil
    let onClose: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 1) { onTitleLongPress?() }
                if let subtitle {
                    Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, max(buttonSize, 44) + 24)
            .padding(.vertical, 12)

            HStack {
                Button(action: onClose) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .frame(minWidth: max(buttonSize, 44), minHeight: max(buttonSize, 44))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel(systemImage == "xmark" ? "Tutup" : "Kembali")
                .accessibilityIdentifier("screenCloseButton")
                .confirmationDialog(
                    closeConfirmation?.title ?? "",
                    isPresented: closeConfirmation?.isPresented ?? .constant(false),
                    titleVisibility: .visible
                ) {
                    if let confirmation = closeConfirmation {
                        Button(confirmation.destructiveTitle, role: .destructive) {
                            confirmation.onDiscard()
                        }
                        .accessibilityIdentifier("discardMappingButton")
                        Button(confirmation.cancelTitle, role: .cancel) {}
                    }
                } message: {
                    if let confirmation = closeConfirmation {
                        Text(confirmation.message)
                    }
                }
                Spacer()
                if let confirmationAction {
                    Button(action: confirmationAction) {
                        Image(systemName: "checkmark")
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(minWidth: 44, minHeight: 44)
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

struct ScreenCloseConfirmation {
    let isPresented: Binding<Bool>
    let title: String
    let message: String
    let destructiveTitle: String
    let cancelTitle: String
    let onDiscard: () -> Void
}

#Preview("Header · Detail Kebun", traits: .sizeThatFitsLayout) {
    ScreenHeader(title: "Detail Kebun", systemImage: "chevron.left", onClose: {})
        .frame(width: 402)
}
#Preview("Header · Formulir", traits: .sizeThatFitsLayout) {
    ScreenHeader(title: "Riwayat Pemupukan", confirmationAction: {}, onClose: {})
        .frame(width: 402)
}
