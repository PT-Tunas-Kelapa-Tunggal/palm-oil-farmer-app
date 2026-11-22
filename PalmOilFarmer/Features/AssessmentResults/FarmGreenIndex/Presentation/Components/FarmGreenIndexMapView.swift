import SwiftUI

/// Background interactive map view showing the aerial farm scan with tree condition crowns and marker pins.
/// Sliced from Sketch: "Hasil Peninjauan / Peta Kondisi Kebun / Collapsed" -> "Frame", "oil_palm_field_tree_vari_quartiles Background Removed", "Lokasi Saya"
public struct FarmGreenIndexMapView: View {
    public let mapImageName: String?
    public let orthomosaic: FarmOrthomosaicMapData?
    public let pins: [TreePinItem]
    public let selectedPin: TreePinItem?
    public let selectedCategory: TreeConditionCategory?
    public let showsZones: Bool
    public var onSelectPin: ((TreePinItem) -> Void)?
    public var onRecenter: (() -> Void)?
    public var onTapBackground: (() -> Void)?

    public init(
        mapImageName: String? = "FarmGreenIndexMap",
        orthomosaic: FarmOrthomosaicMapData? = nil,
        pins: [TreePinItem] = [],
        selectedPin: TreePinItem? = nil,
        selectedCategory: TreeConditionCategory? = nil,
        showsZones: Bool = false,
        onSelectPin: ((TreePinItem) -> Void)? = nil,
        onRecenter: (() -> Void)? = nil,
        onTapBackground: (() -> Void)? = nil
    ) {
        self.mapImageName = mapImageName
        self.orthomosaic = orthomosaic
        self.pins = pins
        self.selectedPin = selectedPin
        self.selectedCategory = selectedCategory
        self.showsZones = showsZones
        self.onSelectPin = onSelectPin
        self.onRecenter = onRecenter
        self.onTapBackground = onTapBackground
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background Satellite NDVI Map
                if usesGeoreferencedOrthomosaic, let orthomosaic {
                    OrthomosaicMapKitView(
                        data: orthomosaic,
                        pins: pins,
                        selectedPin: selectedPin,
                        selectedCategory: selectedCategory,
                        showsZones: showsZones,
                        showsTrees: !showsZones,
                        onSelectPin: { onSelectPin?($0) }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Group {
                        if let mapImageName, let uiImage = UIImage(named: mapImageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else if let fallback = UIImage(named: "FarmGreennessMap") ?? UIImage(named: "ResultOverviewMap") {
                            Image(uiImage: fallback)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [KropsTheme.surfaceInverseRaised, KropsTheme.surfaceInverse],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture { onTapBackground?() }
                }

                // Top gradient overlay for navigation bar readability
                LinearGradient(
                    colors: [Color.black.opacity(0.60), Color.black.opacity(0.20), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
                .allowsHitTesting(false)

                // Interactive Tree Marker Pins
                if !usesGeoreferencedOrthomosaic {
                    ForEach(visiblePins) { pin in
                        let xPos = pin.coordinateX * geometry.size.width
                        let yPos = pin.coordinateY * geometry.size.height
                        let isSelected = selectedPin?.id == pin.id

                        Button(action: { onSelectPin?(pin) }) {
                            treePinMarker(pin, isSelected: isSelected)
                        }
                        .buttonStyle(.plain)
                        .position(x: xPos, y: yPos)
                    }
                }

                // Floating "Lokasi Saya" button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        // Floating "Lokasi Saya" button with Liquid Glass
                        Button(action: { onRecenter?() }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(KropsTheme.labelPrimary)
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: Circle())
                        .accessibilityLabel("Lokasi Saya")
                        .padding(.trailing, 16)
                        .padding(.bottom, 280) // Sits comfortably above bottom sheet
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private var usesGeoreferencedOrthomosaic: Bool {
        guard let orthomosaic else { return false }
        return orthomosaic.imageURL != nil && orthomosaic.imagePixelWidth > 0
            && orthomosaic.imagePixelHeight > 0 && orthomosaic.farmBoundary.count >= 3
    }

    private var visiblePins: [TreePinItem] {
        guard !showsZones else { return [] }
        guard let selectedCategory else { return pins }
        return pins.filter { $0.category == selectedCategory }
    }

    private func treePinMarker(_ pin: TreePinItem, isSelected: Bool) -> some View {
        let pinColor = pin.category.color

        return VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 28 : 20, height: isSelected ? 28 : 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                if isSelected {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.white)
                }
            }

            if isSelected {
                Text(pin.treeNumber)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.75))
                    .clipShape(Capsule())
            }
        }
    }
}


#Preview {
    FarmGreenIndexMapView(
        pins: FarmGreenIndexItem.sample.pins,
        selectedPin: FarmGreenIndexItem.sample.pins.first
    )
}

