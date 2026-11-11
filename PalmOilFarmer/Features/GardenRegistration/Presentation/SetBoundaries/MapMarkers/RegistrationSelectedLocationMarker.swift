import SwiftUI

/// Map marker for a searched place: name label + `RegistrationLocationPin`.
struct RegistrationSelectedLocationMarker: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let name: String

    var body: some View {
        VStack(spacing: 8) {
            // The panel already presents the full name at accessibility sizes.
            if !dynamicTypeSize.isAccessibilitySize {
                Text(name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 180)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white, in: Capsule())
            }
            RegistrationLocationPin()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lokasi terpilih, \(name)")
    }
}

#if DEBUG
#Preview("Penanda lokasi terpilih", traits: .sizeThatFitsLayout) {
    RegistrationSelectedLocationMarker(name: "SMKN 1 Gunung Kijang")
        .padding(24)
        .background(.black.opacity(0.6))
}
#endif
