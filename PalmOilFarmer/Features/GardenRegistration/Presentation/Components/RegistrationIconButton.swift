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
        .foregroundStyle(isProminent ? RegistrationStyle.onAction : .primary)
        .background {
            if isProminent { Circle().fill(RegistrationStyle.actionTint) }
        }
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(label)
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
    .background(RegistrationStyle.background)
}
#endif
