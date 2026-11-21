import SwiftUI

public struct FertilizingMapCanvasView: View {
    public let mode: AreaDivisionMode
    public let zones: [FertilizingZoneDetail]
    public let selectedFertilizerName: String
    public let selectedFertilizerTotalDose: String
    public let selectedZone: FertilizingZoneDetail?
    public let orthomosaic: FarmOrthomosaicMapData?
    public let hidesZoneLabels: Bool
    public let onSelectZone: (FertilizingZoneDetail) -> Void

    public init(
        mode: AreaDivisionMode,
        zones: [FertilizingZoneDetail],
        selectedFertilizerName: String,
        selectedFertilizerTotalDose: String = "",
        selectedZone: FertilizingZoneDetail?,
        orthomosaic: FarmOrthomosaicMapData? = nil,
        hidesZoneLabels: Bool = false,
        onSelectZone: @escaping (FertilizingZoneDetail) -> Void
    ) {
        self.mode = mode
        self.zones = zones
        self.selectedFertilizerName = selectedFertilizerName
        self.selectedFertilizerTotalDose = selectedFertilizerTotalDose
        self.selectedZone = selectedZone
        self.orthomosaic = orthomosaic
        self.hidesZoneLabels = hidesZoneLabels
        self.onSelectZone = onSelectZone
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                if let orthomosaic {
                    FertilizingMapKitView(
                        data: orthomosaic,
                        zones: zones,
                        mode: mode,
                        hidesZoneLabels: hidesZoneLabels,
                        wholeFarmDoseText: selectedFertilizerTotalDose,
                        selectedZone: selectedZone,
                        onSelectZone: onSelectZone
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    mapLayer(geometry: geometry)
                }
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
                if !hidesZoneLabels {
                    ForEach(zones) { zone in
                        zoneBadge(zone: zone, in: geometry)
                    }
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

                Text("\(zone.doseKg.formatted(.number.precision(.fractionLength(0...1)))) kg")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(KropsTheme.surfaceInverse.opacity(0.88))
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
                .fill(KropsTheme.surfaceInverse.opacity(0.92))
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
                .fill(KropsTheme.surfaceInverse.opacity(0.92))
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

}
