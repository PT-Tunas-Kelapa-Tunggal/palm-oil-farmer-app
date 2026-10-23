import SwiftUI

/// A vector seedling matching the empty-state illustration in Sketch.
struct SeedlingIcon: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / 52
            Path { path in
                path.move(to: CGPoint(x: 26, y: 39))
                path.addLine(to: CGPoint(x: 26, y: 26))
                path.addCurve(
                    to: CGPoint(x: 47, y: 3),
                    control1: CGPoint(x: 26, y: 13),
                    control2: CGPoint(x: 36, y: 3)
                )
                path.addCurve(
                    to: CGPoint(x: 26, y: 26),
                    control1: CGPoint(x: 45, y: 20),
                    control2: CGPoint(x: 36, y: 26)
                )
                path.addCurve(
                    to: CGPoint(x: 5, y: 8),
                    control1: CGPoint(x: 25, y: 17),
                    control2: CGPoint(x: 16, y: 8)
                )
                path.addCurve(
                    to: CGPoint(x: 26, y: 26),
                    control1: CGPoint(x: 6, y: 21),
                    control2: CGPoint(x: 15, y: 27)
                )
            }
            .applying(CGAffineTransform(scaleX: scale, y: scale))
            .stroke(style: StrokeStyle(lineWidth: 4 * scale, lineCap: .round, lineJoin: .round))

            ForEach(0..<7) { index in
                let x = CGFloat(index) * 7 + 5
                let y = 43 + abs(CGFloat(index) - 3) * 1.5
                Circle()
                    .frame(width: 4 * scale, height: 4 * scale)
                    .position(x: x * scale, y: y * scale)
            }
        }
        .frame(width: 52, height: 52)
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Seedling Icon", traits: .sizeThatFitsLayout) {
    SeedlingIcon()
        .foregroundStyle(KropsTheme.secondaryText)
        .padding(24)
        .background(KropsTheme.background)
}
#endif
