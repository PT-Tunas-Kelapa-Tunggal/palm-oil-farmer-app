import SwiftUI

/// A schematic planting grid for the empty garden list; it carries no map data.
struct GardenOverviewIllustration: View {
    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3)
            context.fill(Path(bounds), with: .color(Color(white: 0.32)))
            context.stroke(Path(bounds), with: .color(.white), lineWidth: 2)
            let columnSpacing = bounds.width / 9
            let rowSpacing = bounds.height / 9
            for row in 0..<9 {
                for column in 0..<9 {
                    let x = bounds.minX + columnSpacing * (CGFloat(column) + 0.5)
                    let y = bounds.minY + rowSpacing * (CGFloat(row) + 0.5)
                    let canopy = CGRect(x: x - 7, y: y - 6, width: 14, height: 12)
                    context.fill(Path(ellipseIn: canopy), with: .color(.white.opacity(0.18)))
                    context.stroke(Path(ellipseIn: canopy), with: .color(.white.opacity(0.75)), lineWidth: 0.8)
                    var trunk = Path()
                    trunk.move(to: CGPoint(x: x, y: y - 5))
                    trunk.addLine(to: CGPoint(x: x, y: y - 10))
                    context.stroke(trunk, with: .color(.white.opacity(0.75)), lineWidth: 0.8)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Garden planting grid", traits: .sizeThatFitsLayout) {
    GardenOverviewIllustration().frame(width: 216, height: 206).padding()
}
