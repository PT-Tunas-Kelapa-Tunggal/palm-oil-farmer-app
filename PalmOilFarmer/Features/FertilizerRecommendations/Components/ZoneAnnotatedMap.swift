import SwiftUI
import UIKit

struct ZoneAnnotatedMap: View {
    let image: UIImage
    let areas: [FertilizerAllocationArea]
    var selectedAreaID: Binding<String>? = nil
    var highlightedAreaID: String? = nil
    var locationPoint: FertilizerMapPoint? = nil
    var contentMode: ContentMode = .fit
    var focusPoint: FertilizerMapPoint? = nil

    var body: some View {
        GeometryReader { geometry in
            let fittedSize = fittedImageSize(in: geometry.size)
            let imageOrigin: CGPoint = {
                if contentMode == .fill, let focusPoint {
                    return CGPoint(
                        x: geometry.size.width / 2 - fittedSize.width * focusPoint.x,
                        y: geometry.size.height / 2 - fittedSize.height * focusPoint.y
                    )
                }
                return CGPoint(
                    x: (geometry.size.width - fittedSize.width) / 2,
                    y: (geometry.size.height - fittedSize.height) / 2
                )
            }()

            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: fittedSize.width, height: fittedSize.height)
                    .position(
                        x: imageOrigin.x + fittedSize.width / 2,
                        y: imageOrigin.y + fittedSize.height / 2
                    )

                ForEach(areas) { area in
                    if let point = area.mapPoint {
                        zoneMarker(for: area)
                            .position(
                                x: imageOrigin.x + fittedSize.width * point.x,
                                y: imageOrigin.y + fittedSize.height * point.y
                            )
                            .accessibilityLabel("Zona \(zoneNumber(from: area.id))")
                    }
                }

                if let locationPoint {
                    Image(systemName: "location.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.blue, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
                        .position(
                            x: imageOrigin.x + fittedSize.width * locationPoint.x,
                            y: imageOrigin.y + fittedSize.height * locationPoint.y
                        )
                        .accessibilityLabel("Posisi Anda, simulasi")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }

    @ViewBuilder
    private func zoneMarker(for area: FertilizerAllocationArea) -> some View {
        if let selectedAreaID {
            let isSelected = selectedAreaID.wrappedValue == area.id
            Button {
                selectedAreaID.wrappedValue = area.id
            } label: {
                markerLabel(for: area, isSelected: isSelected)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pilih zona \(zoneNumber(from: area.id))")
            .accessibilityValue(isSelected ? "Zona dipilih" : "Ketuk untuk melihat alokasi zona")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            markerLabel(for: area, isSelected: highlightedAreaID == area.id)
                .accessibilityLabel("Zona \(zoneNumber(from: area.id))")
        }
    }

    private func markerLabel(for area: FertilizerAllocationArea, isSelected: Bool) -> some View {
        Text(zoneNumber(from: area.id))
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(isSelected ? Color.accentColor : Color.black.opacity(0.76), in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .contentShape(Circle())
    }

    private func fittedImageSize(in container: CGSize) -> CGSize {
        guard image.size.width > 0, image.size.height > 0 else { return container }
        let scale = contentMode == .fill
            ? max(container.width / image.size.width, container.height / image.size.height)
            : min(container.width / image.size.width, container.height / image.size.height)
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    private func zoneNumber(from id: String) -> String {
        let digits = id.filter(\.isNumber)
        return digits.isEmpty ? id : digits
    }
}
