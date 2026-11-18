import SwiftUI

/// Numbered corner point of the boundary being drawn (Sketch "Atom / Vertex Pin").
/// Every point looks the same; the active one only gets a thicker white border.
struct RegistrationBoundaryMarker: View {
    let number: Int
    var isActive = false
    @ScaledMetric(relativeTo: .caption) private var size = 30

    var body: some View {
        Text(number.formatted())
            .font(.caption.bold())
            .foregroundStyle(KropsTheme.labelInversePrimary)
            .frame(minWidth: size, minHeight: size)
            .background(KropsTheme.accentHero, in: Circle())
            .overlay { Circle().stroke(KropsTheme.labelInversePrimary, lineWidth: isActive ? 3 : 2) }
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
