import SwiftUI

/// The map photo with numbered areas and header, shared by the review result screens.
struct ReviewMapHero: View {
    let result: ReviewResult
    let documentIcon: String
    let topInset: CGFloat

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Image(result.mapImage)
            .resizable()
            .aspectRatio(1206.0 / 1140.0, contentMode: .fit)
            .overlay { areaOverlay }
            .accessibilityLabel("Peta \(result.gardenName) dengan \(result.areas.count) area")
            .overlay(alignment: .top) {
                LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 185)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                header.padding(.top, topInset + KropsTheme.Spacing.compact)
            }
    }

    private var areaOverlay: some View {
        GeometryReader { geometry in
            ForEach(result.areas) { area in
                AreaOutline(points: area.outline)
                    .stroke(.white.opacity(0.85), lineWidth: 1.5)
                Text("\(area.id)")
                    .font(.caption2.weight(.semibold))
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(.black.opacity(0.35), in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .position(x: area.center.x * geometry.size.width,
                              y: area.center.y * geometry.size.height)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: KropsTheme.Spacing.field) {
            ReviewIconButton(systemImage: "chevron.left", accessibilityLabel: "Kembali", style: .onPhoto,
                             font: .body.weight(.medium)) { dismiss() }

            VStack(alignment: .leading, spacing: 2) {
                Text(result.gardenName).font(.title2.bold())
                Text(result.locationName).font(.footnote)
            }
            .foregroundStyle(.white)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .frame(maxWidth: .infinity, alignment: .leading)

            ReviewCircleIcon(systemImage: documentIcon, style: .onPhoto, font: .body.weight(.medium))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, KropsTheme.Spacing.screen)
    }
}

struct AreaOutline: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
            path.closeSubpath()
        }
    }
}
