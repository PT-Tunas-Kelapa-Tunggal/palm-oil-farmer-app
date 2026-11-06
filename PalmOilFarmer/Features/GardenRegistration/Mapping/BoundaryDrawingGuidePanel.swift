import SwiftUI

struct BoundaryDrawingGuidePanel: View {
    let onContinue: () -> Void

    var body: some View {
        MapBottomPanel {
            VStack(spacing: 24) {
                Text("Ketuk peta untuk menandai sudut-sudut kebun Anda.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                RegistrationPrimaryButton(title: "Saya mengerti", action: onContinue)
            }
        }
    }
}

/// Illustrates boundary drawing over the map without intercepting touches.
struct BoundaryDrawingGuideOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let points = [
                CGPoint(x: 0.23, y: 0.25), CGPoint(x: 0.36, y: 0.61),
                CGPoint(x: 0.82, y: 0.61), CGPoint(x: 0.68, y: 0.21)
            ].map { CGPoint(x: $0.x * geometry.size.width, y: $0.y * geometry.size.height) }
            let boundary = Path { path in
                path.addLines(points)
                path.closeSubpath()
            }
            boundary.fill(.white.opacity(0.2))
            boundary.stroke(.white.opacity(0.9), lineWidth: 2)
            ForEach(points.indices, id: \.self) { index in
                RegistrationBoundaryMarker(number: index + 1)
                    .position(points[index])
            }
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-20))
                .position(x: points[3].x + 24, y: points[3].y + 28)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Panduan menggambar batas") {
    Color.gray
        .overlay(alignment: .bottom) {
            BoundaryDrawingGuidePanel(onContinue: {})
        }
        .ignoresSafeArea(.container, edges: .bottom)
}
#Preview("Panduan menggambar batas · Teks besar") {
    Color.gray
        .overlay(alignment: .bottom) {
            BoundaryDrawingGuidePanel(onContinue: {})
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
