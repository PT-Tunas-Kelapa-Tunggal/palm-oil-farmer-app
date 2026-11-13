import SwiftUI

public struct FertilizingMapCanvasView: View {
    public let mode: AreaDivisionMode
    public let zones: [FertilizingZoneDetail]
    public let selectedFertilizerName: String
    public let selectedZone: FertilizingZoneDetail?
    public let userLocation: CGPoint
    public let onSelectZone: (FertilizingZoneDetail) -> Void

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    public init(
        mode: AreaDivisionMode,
        zones: [FertilizingZoneDetail],
        selectedFertilizerName: String,
        selectedZone: FertilizingZoneDetail?,
        userLocation: CGPoint,
        onSelectZone: @escaping (FertilizingZoneDetail) -> Void
    ) {
        self.mode = mode
        self.zones = zones
        self.selectedFertilizerName = selectedFertilizerName
        self.selectedZone = selectedZone
        self.userLocation = userLocation
        self.onSelectZone = onSelectZone
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                mapLayer(geometry: geometry)
                    .scaleEffect(zoomScale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastZoomScale
                                    lastZoomScale = value
                                    let newScale = zoomScale * delta
                                    zoomScale = min(max(newScale, 0.8), 3.5)
                                }
                                .onEnded { _ in
                                    lastZoomScale = 1.0
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
            }
        }
    }

    @ViewBuilder
    private func mapLayer(geometry: GeometryProxy) -> some View {
        let canvasWidth = geometry.size.width
        let canvasHeight = geometry.size.height

        ZStack {
            // Map Image based on mode
            switch mode {
            case .perZona:
                Image("FertilizingZoneMap")
                    .resizable()
                    .scaledToFit()
                    .frame(width: canvasWidth)

                // 6 Zone Badges
                ForEach(zones) { zone in
                    zoneBadge(zone: zone, in: geometry)
                }

            case .perPohon:
                Image("FertilizingTreeMap")
                    .resizable()
                    .scaledToFit()
                    .frame(width: canvasWidth)

                // Selected Palm Tree Badge Callout
                treeBadgeCallout(in: geometry)

            case .wholeFarm:
                Image("FertilizingWholeFarmMap")
                    .resizable()
                    .scaledToFit()
                    .frame(width: canvasWidth)

                // Whole Farm Central Badge
                wholeFarmBadge(in: geometry)
            }

            // User Location GPS Marker
            userLocationMarker(in: geometry)
        }
    }

    // MARK: - Badges

    private func zoneBadge(zone: FertilizingZoneDetail, in geometry: GeometryProxy) -> some View {
        let isSelected = selectedZone?.id == zone.id

        return Button {
            onSelectZone(zone)
        } label: {
            VStack(spacing: 2) {
                Text(zone.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(Int(zone.doseKg)) kg")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0x14 / 255, green: 0x15 / 255, blue: 0x17 / 255).opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? Color.white : Color.white.opacity(0.25),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .position(
            x: geometry.size.width * zone.relativeX,
            y: geometry.size.height * zone.relativeY
        )
    }

    private func treeBadgeCallout(in geometry: GeometryProxy) -> some View {
        // Pointing to tree near center right
        VStack(spacing: 2) {
            Text(selectedFertilizerName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            Text("1,5 kg")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0x14 / 255, green: 0x15 / 255, blue: 0x17 / 255).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        .position(
            x: geometry.size.width * 0.65,
            y: geometry.size.height * 0.40
        )
    }

    private func wholeFarmBadge(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 3) {
            Text("Seluruh Kebun")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            Text("120 kg")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0x14 / 255, green: 0x15 / 255, blue: 0x17 / 255).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        .position(
            x: geometry.size.width * 0.50,
            y: geometry.size.height * 0.48
        )
    }

    private func userLocationMarker(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Pulsing translucent outer ring
            Circle()
                .fill(Color(red: 0x00 / 255, green: 0x7A / 255, blue: 0xFF / 255).opacity(0.2))
                .frame(width: 44, height: 44)

            // Inner circle
            Circle()
                .fill(Color(red: 0x00 / 255, green: 0x7A / 255, blue: 0xFF / 255))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
        }
        .position(
            x: geometry.size.width * userLocation.x,
            y: geometry.size.height * userLocation.y
        )
    }
}
