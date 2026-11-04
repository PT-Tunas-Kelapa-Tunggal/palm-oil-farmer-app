import SwiftUI
import MapKit

struct LocationMapPreview: View {
    let location: GardenLocation
    var referenceImage: String? = nil

    var body: some View {
        Group {
            if let referenceImage {
                Image(referenceImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: location.coordinate.mapCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )), interactionModes: [])
                .mapStyle(.imagery)
                .mapControls {}
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .id(location.id)
    }
}

#if DEBUG
#Preview("Location Map", traits: .sizeThatFitsLayout) {
    LocationMapPreview(location: GardenPreviewData.location, referenceImage: "AddressSatelliteSource")
        .frame(width: 338, height: 141)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(24)
}
#endif
