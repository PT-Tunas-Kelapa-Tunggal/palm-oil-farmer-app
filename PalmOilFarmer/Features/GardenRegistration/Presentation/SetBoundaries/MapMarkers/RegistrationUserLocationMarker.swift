import SwiftUI

/// Map marker for the farmer's live position (GPS and resumed-draft mapping).
struct RegistrationUserLocationMarker: View {
    var body: some View {
        Circle()
            .fill(RegistrationStyle.actionTint)
            .frame(width: 22, height: 22)
            .overlay { Circle().stroke(.white, lineWidth: 4) }
            .padding(15)
            .background(RegistrationStyle.actionTint.opacity(0.35), in: Circle())
            .overlay { Circle().stroke(.white.opacity(0.7), lineWidth: 1.5) }
            .accessibilityLabel("Posisi Anda sekarang")
    }
}

#if DEBUG
#Preview("Penanda posisi saya", traits: .sizeThatFitsLayout) {
    RegistrationUserLocationMarker()
        .padding(24)
        .background(.black.opacity(0.6))
}
#endif
