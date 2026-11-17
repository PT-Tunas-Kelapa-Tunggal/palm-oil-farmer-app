import SwiftUI

/// Numbered corner point of the boundary being drawn.
struct RegistrationBoundaryMarker: View {
    let number: Int
    var isActive = false
    @ScaledMetric(relativeTo: .footnote) private var size = 28

    var body: some View {
        Text(number.formatted())
            .font(.footnote)
            .foregroundStyle(isActive ? KropsTheme.labelInversePrimary : KropsTheme.accentHero)
            .frame(minWidth: size, minHeight: size)
            .background(isActive ? KropsTheme.accentHero : KropsTheme.surfaceCard, in: Circle())
            .overlay { Circle().stroke(KropsTheme.accentHero, lineWidth: 2) }
            .accessibilityLabel("Titik \(number)")
    }
}

#if DEBUG
#Preview("Titik sudut batas", traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        RegistrationBoundaryMarker(number: 1)
        RegistrationBoundaryMarker(number: 2)
        RegistrationBoundaryMarker(number: 3, isActive: true)
    }
    .padding(24)
    .background(.black.opacity(0.6))
}
#endif
