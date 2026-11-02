import SwiftUI

struct AreaDirectionsView: View {
    let directions: AreaDirections

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(directions.mapImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                areaMarker(in: geometry.size)
                walkerMarker
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.68)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Peta menuju Area \(directions.area.id)")
        }
        .ignoresSafeArea()
        .overlay(alignment: .top) { header }
        .overlay(alignment: .bottom) { distanceCard }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func areaMarker(in size: CGSize) -> some View {
        ZStack {
            AreaOutline(points: directions.area.outline)
                .stroke(.white.opacity(0.7), lineWidth: 2)
            Text("\(directions.area.id)")
                .font(.title3.weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.black.opacity(0.55), in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .position(x: directions.area.center.x * size.width,
                          y: directions.area.center.y * size.height)
        }
    }

    private var walkerMarker: some View {
        VStack(spacing: -6) {
            DirectionCone()
                .fill(LinearGradient(colors: [.clear, .white.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                .frame(width: 104, height: 72)
            Image(systemName: "figure.walk")
                .font(.title2)
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                .foregroundStyle(.black)
                .frame(width: 62, height: 62)
                .background(.white, in: Circle())
        }
    }

    private var header: some View {
        ZStack {
            Text("Navigasi")
                .font(.headline)
                .foregroundStyle(.white)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityAddTraits(.isHeader)
            HStack {
                ReviewIconButton(systemImage: "xmark", accessibilityLabel: "Tutup", style: .onPhoto) { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, KropsTheme.Spacing.field)
        .padding(.top, KropsTheme.Spacing.compact)
    }

    private var distanceCard: some View {
        VStack(spacing: 0) {
            ReviewAmountText(value: directions.distance, size: 48)
            Text("Area \(directions.area.id)").font(.title3.weight(.semibold))
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .foregroundStyle(.white)
        .padding(.horizontal, KropsTheme.Spacing.content)
        .padding(.vertical, KropsTheme.Spacing.screen)
        .frame(minWidth: 244)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
        .padding(.horizontal, KropsTheme.Spacing.screen)
        .padding(.bottom, KropsTheme.Spacing.compact)
    }
}

/// The widening beam above the walker, pointing toward the destination.
private struct DirectionCone: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX + 14, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX - 14, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

#if DEBUG
#Preview("Navigasi ke Area") {
    NavigationStack {
        AreaDirectionsView(directions: .sample)
    }
}
#endif
