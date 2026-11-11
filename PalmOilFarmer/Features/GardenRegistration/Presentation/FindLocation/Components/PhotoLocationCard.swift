import SwiftUI
import UIKit
import MapKit

/// Card with the photo location on a small satellite map.
struct PhotoLocationCard: View {
    let location: GardenLocation
    var image: UIImage?
    var referenceMapImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(location.name)
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            Group {
                if let referenceMapImage {
                    Image(referenceMapImage).resizable().scaledToFill()
                } else {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: location.coordinate.mapCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                    )), interactionModes: []) {
                        Annotation("Lokasi foto", coordinate: location.coordinate.mapCoordinate) {
                            PhotoLocationMarker(image: image)
                        }
                    }
                    .mapStyle(.imagery)
                    .mapControls {}
                }
            }
            .frame(height: 160)
            .clipped()
        }
        .background(RegistrationStyle.surface, in: RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius))
        .clipShape(RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius))
    }
}

#if DEBUG
#Preview("Kartu lokasi foto", traits: .sizeThatFitsLayout) {
    PhotoLocationCard(location: GardenRegistrationPreview.photoLocation,
                      image: UIImage(named: "RegistrationPhotoReference"),
                      referenceMapImage: "RegistrationPhotoSatellite")
        .padding()
}
#endif
