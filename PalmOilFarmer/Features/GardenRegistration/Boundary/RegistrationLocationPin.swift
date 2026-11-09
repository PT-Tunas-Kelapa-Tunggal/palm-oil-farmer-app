import SwiftUI

/// Neutral map markers use an opaque semantic color pair for legibility over satellite imagery.
struct RegistrationLocationPin: View {
    var body: some View {
        VStack(spacing: -2) {
            Circle()
                .fill(RegistrationStyle.actionTint)
                .frame(width: 42, height: 42)
                .overlay { Image(systemName: "mappin").foregroundStyle(.white) }
                .overlay { Circle().stroke(RegistrationStyle.onAction, lineWidth: 3) }
            Image(systemName: "triangle.fill")
                .font(.system(size: 12))
                .rotationEffect(.degrees(180))
                .foregroundStyle(RegistrationStyle.onAction)
        }
        .accessibilityHidden(true)
    }
}

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

struct RegistrationBoundaryMarker: View {
    let number: Int
    var isActive = false
    @ScaledMetric(relativeTo: .footnote) private var size = 28

    var body: some View {
        Text(number.formatted())
            .font(.footnote)
            .foregroundStyle(isActive ? .white : RegistrationStyle.actionTint)
            .frame(minWidth: size, minHeight: size)
            .background(isActive ? RegistrationStyle.actionTint : .white, in: Circle())
            .overlay { Circle().stroke(RegistrationStyle.actionTint, lineWidth: 2) }
            .accessibilityLabel("Titik \(number)")
    }
}
