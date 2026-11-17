import SwiftUI
import MapKit

/// Hero header view showing the satellite map with gradient fades, screen title, and back button.
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Frame", "Judul Layar", "Tombol Kembali"
public struct ResultOverviewMapHeaderView: View {
    // The map viewport never changes size when the refresh area stretches.
    private let mapCanvasHeight: CGFloat = 720
    private let mapCanvasOffset: CGFloat = 180

    public let gardenName: String
    public let locationName: String
    public let heroImageName: String?
    public let farmBoundary: [FarmMapCoordinate]
    public let height: CGFloat
    public let showsNavigation: Bool
    public var onBack: (() -> Void)?

    public init(
        gardenName: String,
        locationName: String,
        heroImageName: String? = nil,
        farmBoundary: [FarmMapCoordinate] = [],
        height: CGFloat = 360,
        showsNavigation: Bool = true,
        onBack: (() -> Void)? = nil
    ) {
        self.gardenName = gardenName
        self.locationName = locationName
        self.heroImageName = heroImageName
        self.farmBoundary = farmBoundary
        self.height = height
        self.showsNavigation = showsNavigation
        self.onBack = onBack
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Background Satellite Map (contained within screen bounds)
            Color.clear
                .overlay(alignment: .top) {
                    if let camera = mapCamera {
                        Map(initialPosition: .camera(camera), interactionModes: []) {
                            MapPolygon(coordinates: farmBoundary.map {
                                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                            })
                            .foregroundStyle(.white.opacity(0.18))
                            .stroke(.white.opacity(0.9), lineWidth: 1.5)
                        }
                        .mapStyle(.imagery(elevation: .flat))
                        .allowsHitTesting(false)
                        .frame(height: mapCanvasHeight)
                        .offset(y: -mapCanvasOffset)
                    } else if let heroImageName, let uiImage = UIImage(named: heroImageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: mapCanvasHeight)
                            .offset(y: -mapCanvasOffset)
                    } else if let fallback = UIImage(named: "ResultOverviewMap") ?? UIImage(named: "ProfileHiFiMap") {
                        Image(uiImage: fallback)
                            .resizable()
                            .scaledToFill()
                            .frame(height: mapCanvasHeight)
                            .offset(y: -mapCanvasOffset)
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0.16, green: 0.28, blue: 0.22), Color(red: 0.10, green: 0.18, blue: 0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: mapCanvasHeight)
                        .offset(y: -mapCanvasOffset)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()

            // Top gradient overlay for status bar readability
            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 140)

            // Bottom gradient overlay to blend into the #F2F4F7 page background
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color(red: 0.95, green: 0.96, blue: 0.97)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)

            // Navigation bar with Back button and centered Title (positioned below status bar/Dynamic Island)
            if showsNavigation {
                HStack(alignment: .center) {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Kembali")

                Spacer()

                VStack(spacing: 2) {
                    Text(gardenName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)

                    Text(locationName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .multilineTextAlignment(.center)

                Spacer()

                // Spacer balance for back button
                Color.clear
                    .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private var mapCamera: MapCamera? {
        guard farmBoundary.count >= 3,
              farmBoundary.allSatisfy({ (-90...90).contains($0.latitude) && (-180...180).contains($0.longitude) }) else {
            return nil
        }
        let latitudes = farmBoundary.map(\.latitude)
        let longitudes = farmBoundary.map(\.longitude)
        guard let minLatitude = latitudes.min(), let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(), let maxLongitude = longitudes.max() else {
            return nil
        }
        let southwest = CLLocation(latitude: minLatitude, longitude: minLongitude)
        let northeast = CLLocation(latitude: maxLatitude, longitude: maxLongitude)
        let farmDiagonal = southwest.distance(from: northeast)
        return MapCamera(
            centerCoordinate: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            distance: max(500, farmDiagonal * 4.4)
        )
    }
}

#Preview {
    ResultOverviewMapHeaderView(
        gardenName: "Belakang Rumah",
        locationName: "Malang Rapat, Bintan"
    )
}

