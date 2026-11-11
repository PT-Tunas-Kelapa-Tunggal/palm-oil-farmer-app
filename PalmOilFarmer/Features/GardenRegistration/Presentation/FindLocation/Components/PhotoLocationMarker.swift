import SwiftUI
import UIKit

/// Map marker showing the chosen photo.
struct PhotoLocationMarker: View {
    var image: UIImage?

    var body: some View {
        VStack(spacing: -1) {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo.fill").font(.title2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 48, height: 48)
            .background(.background)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay { RoundedRectangle(cornerRadius: 4).stroke(.white, lineWidth: 3) }
            Image(systemName: "triangle.fill")
                .font(.caption2)
                .rotationEffect(.degrees(180))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Lokasi foto terpilih")
    }
}

#if DEBUG
#Preview("Penanda foto", traits: .sizeThatFitsLayout) {
    HStack(spacing: 24) {
        PhotoLocationMarker(image: UIImage(named: "RegistrationPhotoReference"))
        PhotoLocationMarker()
    }
    .padding(24)
    .background(.black.opacity(0.6))
}
#endif
