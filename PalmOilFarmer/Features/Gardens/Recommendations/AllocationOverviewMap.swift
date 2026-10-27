import SwiftUI
import MapKit

struct AllocationOverviewMap: View {
    let boundary: GardenBoundary
    let areas: [FertilizerAllocationArea]
    let selectedAreaID: String

    var body: some View {
        Map {
            MapPolygon(coordinates: boundary.coordinates)
                .foregroundStyle(.white.opacity(0.1))
                .stroke(.white, lineWidth: 2)
            ForEach(areas) { area in
                if let areaBoundary = area.boundary {
                    MapPolygon(coordinates: areaBoundary.coordinates)
                        .foregroundStyle(.white.opacity(area.id == selectedAreaID ? 0.4 : 0.15))
                        .stroke(.white, lineWidth: area.id == selectedAreaID ? 4 : 1)
                    if let point = area.navigationTarget ?? areaBoundary.points.first {
                        Annotation("", coordinate: point.mapCoordinate) {
                            Text(area.id).font(.caption.bold())
                                .padding(4)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                }
            }
        }
        .mapStyle(.imagery)
        .mapControls {}
        .allowsHitTesting(false)
        .accessibilityLabel("Peta alokasi pupuk, area " + selectedAreaID)
    }
}
