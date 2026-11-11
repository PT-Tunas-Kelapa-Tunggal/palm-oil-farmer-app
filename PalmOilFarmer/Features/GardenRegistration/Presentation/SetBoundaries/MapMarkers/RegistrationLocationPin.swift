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

#if DEBUG
#Preview("Pin lokasi", traits: .sizeThatFitsLayout) {
    RegistrationLocationPin()
        .padding(24)
        .background(.black.opacity(0.6))
}
#endif
