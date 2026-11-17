import SwiftUI
import MapKit

/// Hero header view showing the satellite map with gradient fades, screen title, and back button.
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Frame", "Judul Layar", "Tombol Kembali"
public struct ResultOverviewMapHeaderView: View {
    public let gardenName: String
    public let locationName: String
    public let heroImageName: String?
    public let gardenBoundaryCoordinates: [FarmMapCoordinate]
    public var onBack: (() -> Void)?

    public init(
        gardenName: String,
        locationName: String,
        heroImageName: String? = nil,
        gardenBoundaryCoordinates: [FarmMapCoordinate] = [],
        onBack: (() -> Void)? = nil
    ) {
        self.gardenName = gardenName
        self.locationName = locationName
        self.heroImageName = heroImageName
        self.gardenBoundaryCoordinates = gardenBoundaryCoordinates
        self.onBack = onBack
    }

    private var mapRegion: MKCoordinateRegion? {
        guard gardenBoundaryCoordinates.count >= 3,
              gardenBoundaryCoordinates.allSatisfy({
                  $0.latitude.isFinite && $0.longitude.isFinite
                      && (-90...90).contains($0.latitude)
                      && (-180...180).contains($0.longitude)
              }) else { return nil }

        let latitudes = gardenBoundaryCoordinates.map(\.latitude)
        let longitudes = gardenBoundaryCoordinates.map(\.longitude)
        guard let minLatitude = latitudes.min(), let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(), let maxLongitude = longitudes.max() else { return nil }

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLatitude - minLatitude) * 1.8, 0.0007),
                longitudeDelta: max((maxLongitude - minLongitude) * 1.8, 0.0007)
            )
        )
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Use the saved garden boundary to center the live satellite map.
            Color.clear
                .overlay {
                    if let mapRegion {
                        Map(initialPosition: .region(mapRegion), interactionModes: []) {
                            MapPolygon(coordinates: gardenBoundaryCoordinates.map {
                                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                            })
                            .foregroundStyle(.white.opacity(0.25))
                            .stroke(.white.opacity(0.9), lineWidth: 2)
                        }
                        .mapStyle(.imagery)
                        .allowsHitTesting(false)
                    } else if let heroImageName, let uiImage = UIImage(named: heroImageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else if let fallback = UIImage(named: "ResultOverviewMap") ?? UIImage(named: "ProfileHiFiMap") {
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
                .frame(maxWidth: .infinity)
                .frame(height: 360)
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
                    colors: [Color.clear, KropsTheme.surfaceBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 360)

            // Navigation bar with Back button and centered Title (positioned below status bar/Dynamic Island)
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
        .frame(maxWidth: .infinity)
        .frame(height: 360)
        .clipped()
    }
}

#Preview {
    ResultOverviewMapHeaderView(
        gardenName: "Belakang Rumah",
        locationName: "Malang Rapat, Bintan"
    )
}

