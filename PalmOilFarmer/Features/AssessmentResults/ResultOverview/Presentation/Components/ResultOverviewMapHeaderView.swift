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

    /// The title row ends at 104 pt (60 top + 44); the content cards overlap the map's last 52 pt.
    /// The boundary is framed between them, with 16 pt to spare, like the Profil Kebun header.
    private static let boundaryInsets = EdgeInsets(top: 120, leading: 24, bottom: 68, trailing: 24)

    private var hasValidBoundary: Bool {
        gardenBoundaryCoordinates.count >= 3
            && gardenBoundaryCoordinates.allSatisfy {
                $0.latitude.isFinite && $0.longitude.isFinite
                    && (-90...90).contains($0.latitude)
                    && (-180...180).contains($0.longitude)
            }
    }

    private var boundary: GardenBoundary {
        GardenBoundary(points: gardenBoundaryCoordinates.map {
            GardenCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        })
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Use the saved garden boundary to center the live satellite map.
            Color.clear
                .overlay {
                    if hasValidBoundary {
                        // Same map as Profil Kebun: the boundary always sits below the title.
                        GardenMapView(boundary: boundary, contentInsets: Self.boundaryInsets, zoomOut: 1.1)
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

            // Top gradient overlay for status bar readability (same as the Profil Kebun header)
            LinearGradient(
                colors: [KropsTheme.surfaceInverse.opacity(0.4), KropsTheme.surfaceInverse.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 140)

            // Bottom gradient overlay to blend into the #F2F4F7 page background
            VStack {
                Spacer()
                // Clear until the last ~40 pt, which the overlapping cards mostly cover
                // (same as the Profil Kebun header), so the map is not washed out above the cards.
                LinearGradient(
                    stops: [
                        .init(color: KropsTheme.surfaceBackground.opacity(0), location: 0.76),
                        .init(color: KropsTheme.surfaceBackground, location: 1)
                    ],
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

