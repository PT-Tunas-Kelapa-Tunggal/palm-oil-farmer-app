import SwiftUI

struct BoundaryGuideIllustration: View {
    var body: some View {
        Image("BoundaryGuide")
            .resizable()
            .scaledToFill()
            .overlay(alignment: .topLeading) {
                Text("GIF")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.white, in: Capsule())
                    .foregroundStyle(.secondary)
                    .padding(12)
            }
            .clipped()
            .accessibilityLabel("Ilustrasi titik-titik di sepanjang batas kebun")
    }
}

#Preview("Boundary Guide", traits: .sizeThatFitsLayout) {
    BoundaryGuideIllustration()
        .frame(width: 338, height: 141)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(24)
}
