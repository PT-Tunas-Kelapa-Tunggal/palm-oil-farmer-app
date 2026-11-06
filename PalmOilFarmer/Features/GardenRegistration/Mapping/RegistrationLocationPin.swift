import SwiftUI

/// Neutral map markers use an opaque semantic color pair for legibility over satellite imagery.
struct RegistrationLocationPin: View {
    var body: some View {
        VStack(spacing: -2) {
            Circle()
                .fill(RegistrationStyle.actionTint)
                .frame(width: 46, height: 46)
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
        Image(systemName: "figure.walk")
            .font(.system(size: 14))
            .foregroundStyle(.primary)
            .frame(width: 26, height: 26)
            .background(RegistrationStyle.surface, in: Circle())
            .padding(10)
            .background(Color(uiColor: .tertiarySystemFill), in: Circle())
            .accessibilityLabel("Posisi Anda sekarang")
    }
}

struct RegistrationSelectedLocationMarker: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let name: String

    var body: some View {
        VStack(spacing: 16) {
            // The panel already presents the full name at accessibility sizes.
            if !dynamicTypeSize.isAccessibilitySize {
                Text(name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 180)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            RegistrationLocationPin()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lokasi terpilih, \(name)")
    }
}

struct RegistrationBoundaryMarker: View {
    let number: Int
    @ScaledMetric(relativeTo: .footnote) private var size = 32

    var body: some View {
        Text(number.formatted())
            .font(.footnote)
            .foregroundStyle(RegistrationStyle.onAction)
            .frame(minWidth: size, minHeight: size)
            .background(RegistrationStyle.actionTint, in: Circle())
            .overlay { Circle().stroke(RegistrationStyle.onAction, lineWidth: 2) }
            .accessibilityLabel("Titik \(number)")
    }
}
