import SwiftUI

struct GardenAreaIcon: View {
    var body: some View {
        GeometryReader { geometry in
            let points = [
                CGPoint(x: 0.23, y: 0.15), CGPoint(x: 0.78, y: 0.32),
                CGPoint(x: 0.86, y: 0.85), CGPoint(x: 0.08, y: 0.66)
            ].map { CGPoint(x: $0.x * geometry.size.width, y: $0.y * geometry.size.height) }
            Path { path in
                path.addLines(points)
                path.closeSubpath()
            }
            .stroke(style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))
            ForEach(points.indices, id: \.self) { index in
                Circle().frame(width: 3, height: 3).position(points[index])
            }
        }
        .frame(width: 16, height: 16)
        .accessibilityHidden(true)
    }
}

#Preview("Garden Area Icon", traits: .sizeThatFitsLayout) {
    GardenAreaIcon().padding()
}
