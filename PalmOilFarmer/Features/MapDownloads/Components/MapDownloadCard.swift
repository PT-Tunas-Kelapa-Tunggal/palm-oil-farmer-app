import SwiftUI

struct MapDownloadCard: View {
    let location: GardenLocation
    let state: MapDownloadState
    var referenceMapImage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let referenceMapImage {
                    Image(referenceMapImage).resizable().scaledToFill()
                } else {
                    LocationMapPreview(location: location)
                }
            }
            .frame(height: 201)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            MapDownloadProgressView(state: state, usesCardBackground: false).background(.background)
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }
}
