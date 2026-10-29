import SwiftUI
import UIKit

struct ZoneAnnotatedMap: View {
    let image: UIImage
    let areas: [FertilizerAllocationArea]

    var body: some View {
        GeometryReader { geometry in
            let fittedSize = fittedImageSize(in: geometry.size)
            let imageOrigin = CGPoint(
                x: (geometry.size.width - fittedSize.width) / 2,
                y: (geometry.size.height - fittedSize.height) / 2
            )

            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fittedSize.width, height: fittedSize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                ForEach(areas) { area in
                    if let point = area.mapPoint {
                        Text(zoneNumber(from: area.id))
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.68), in: Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .position(
                                x: imageOrigin.x + fittedSize.width * point.x,
                                y: imageOrigin.y + fittedSize.height * point.y
                            )
                            .accessibilityLabel("Zona \(zoneNumber(from: area.id))")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func fittedImageSize(in container: CGSize) -> CGSize {
        guard image.size.width > 0, image.size.height > 0 else { return container }
        let scale = min(container.width / image.size.width, container.height / image.size.height)
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    private func zoneNumber(from id: String) -> String {
        let digits = id.filter(\.isNumber)
        return digits.isEmpty ? id : digits
    }
}
