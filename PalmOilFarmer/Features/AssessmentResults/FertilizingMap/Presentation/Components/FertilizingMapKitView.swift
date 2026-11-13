import ImageIO
import MapKit
import SwiftUI
import UIKit

/// Satellite MapKit canvas with the bundled orthomosaic and JSON-derived tree/zone boxes.
@MainActor
struct FertilizingMapKitView: UIViewRepresentable {
    let data: FarmOrthomosaicMapData
    let zones: [FertilizingZoneDetail]
    let mode: AreaDivisionMode
    let selectedZone: FertilizingZoneDetail?
    let userLocation: CGPoint
    let onSelectZone: (FertilizingZoneDetail) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.mapType = .satellite
        map.delegate = context.coordinator
        map.isRotateEnabled = true
        map.isPitchEnabled = true
        context.coordinator.update(map, data: data, zones: zones, mode: mode,
                                   selectedZone: selectedZone, userLocation: userLocation,
                                   onSelectZone: onSelectZone)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.update(map, data: data, zones: zones, mode: mode,
                                   selectedZone: selectedZone, userLocation: userLocation,
                                   onSelectZone: onSelectZone)
    }

    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate {
        private var lastData: FarmOrthomosaicMapData?
        private var lastZones: [FertilizingZoneDetail] = []
        private var lastMode: AreaDivisionMode?
        private var lastSelectedZoneID: Int?
        private var lastUserLocation: CGPoint?
        private var imageMapRect: MKMapRect?
        private var zoneAnnotations: [ObjectIdentifier: FertilizingZoneDetail] = [:]
        private var onSelectZone: ((FertilizingZoneDetail) -> Void)?

        func update(
            _ map: MKMapView,
            data: FarmOrthomosaicMapData,
            zones: [FertilizingZoneDetail],
            mode: AreaDivisionMode,
            selectedZone: FertilizingZoneDetail?,
            userLocation: CGPoint,
            onSelectZone: @escaping (FertilizingZoneDetail) -> Void
        ) {
            self.onSelectZone = onSelectZone
            let selectedZoneID = selectedZone?.id
            guard lastData != data || lastZones != zones || lastMode != mode
                    || lastSelectedZoneID != selectedZoneID || lastUserLocation != userLocation else { return }

            let shouldReframe = lastData != data || lastMode != mode
            lastData = data
            lastZones = zones
            lastMode = mode
            lastSelectedZoneID = selectedZoneID
            lastUserLocation = userLocation

            map.removeOverlays(map.overlays)
            map.removeAnnotations(map.annotations)
            zoneAnnotations.removeAll()

            guard let imageURL = data.imageURL,
                  data.imagePixelWidth > 0, data.imagePixelHeight > 0,
                  data.farmBoundary.count >= 3,
                  let farmRect = Self.mapRect(for: data.farmBoundary),
                  let imageRect = Self.imageRect(for: data, inside: farmRect) else { return }
            imageMapRect = imageRect

            if let image = Self.downsampledImage(at: imageURL) {
                map.addOverlay(FertilizingImageOverlay(image: image, rect: imageRect), level: .aboveLabels)
            }

            switch mode {
            case .perZona:
                let zonesByID = Dictionary(uniqueKeysWithValues: zones.map { (Int64($0.id), $0) })
                let zonePolygons = data.zones.compactMap { zone -> MKPolygon? in
                    polygon(for: zone.boundingBox, data: data, rect: imageRect, title: "zone-\(zone.id)")
                }
                map.addOverlays(zonePolygons, level: .aboveLabels)

                for zone in data.zones {
                    guard let detail = zonesByID[zone.id],
                          let center = Self.center(of: zone.boundingBox),
                          let coordinate = Self.coordinate(for: center, data: data, rect: imageRect) else { continue }
                    let annotation = FertilizingZoneAnnotation(detail: detail, coordinate: coordinate)
                    zoneAnnotations[ObjectIdentifier(annotation)] = detail
                    map.addAnnotation(annotation)
                }

            case .perPohon:
                let treePolygons = data.trees.compactMap { tree in
                    polygon(for: tree.boundingBox, data: data, rect: imageRect, title: "tree-\(tree.id)")
                }
                map.addOverlays(treePolygons, level: .aboveLabels)

            case .wholeFarm:
                break
            }

            let locationPixel = PixelPoint(
                x: userLocation.x * Double(data.imagePixelWidth),
                y: userLocation.y * Double(data.imagePixelHeight)
            )
            if let coordinate = Self.coordinate(for: locationPixel, data: data, rect: imageRect) {
                map.addAnnotation(FertilizingUserLocationAnnotation(coordinate: coordinate))
            }

            if shouldReframe {
                map.setVisibleMapRect(
                    farmRect,
                    edgePadding: UIEdgeInsets(top: 130, left: 24, bottom: 300, right: 24),
                    animated: false
                )
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let image = overlay as? FertilizingImageOverlay {
                return FertilizingImageRenderer(overlay: image)
            }
            guard let polygon = overlay as? MKPolygon else { return MKOverlayRenderer(overlay: overlay) }
            let renderer = MKPolygonRenderer(polygon: polygon)
            if polygon.title?.hasPrefix("tree-") == true {
                let treeID = Int64(polygon.title?.replacingOccurrences(of: "tree-", with: "") ?? "") ?? 0
                let label = lastData?.trees.first(where: { $0.id == treeID })?.healthynessLabel ?? .unknown
                let tint = UIColor(hex: Self.color(for: label))
                renderer.strokeColor = tint.withAlphaComponent(0.95)
                renderer.fillColor = tint.withAlphaComponent(0.42)
                renderer.lineWidth = 1.2
            } else {
                let zoneID = Int64(polygon.title?.replacingOccurrences(of: "zone-", with: "") ?? "") ?? 0
                let isSelected = Int64(lastSelectedZoneID ?? -1) == zoneID
                let tint = UIColor.systemTeal
                renderer.strokeColor = tint.withAlphaComponent(0.98)
                renderer.fillColor = tint.withAlphaComponent(isSelected ? 0.35 : 0.17)
                renderer.lineWidth = isSelected ? 3 : 2
            }
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is FertilizingUserLocationAnnotation {
                let reuseID = "fertilizing-user-location"
                let marker = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView)
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                marker.annotation = annotation
                marker.glyphImage = UIImage(systemName: "location.fill")
                marker.markerTintColor = .systemBlue
                marker.canShowCallout = false
                marker.displayPriority = .required
                return marker
            }

            guard let zone = annotation as? FertilizingZoneAnnotation else { return nil }
            let reuseID = "fertilizing-zone"
            let marker = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            marker.annotation = annotation
            marker.glyphText = "\(zone.detail.id)"
            marker.markerTintColor = .systemTeal
            marker.canShowCallout = true
            marker.displayPriority = .required
            return marker
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation,
                  let detail = zoneAnnotations[ObjectIdentifier(annotation)] else { return }
            onSelectZone?(detail)
        }

        private func polygon(for points: [PixelPoint], data: FarmOrthomosaicMapData,
                             rect: MKMapRect, title: String) -> MKPolygon? {
            let coordinates = points.compactMap { Self.coordinate(for: $0, data: data, rect: rect) }
            guard coordinates.count >= 3 else { return nil }
            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            polygon.title = title
            return polygon
        }

        private static func mapRect(for boundary: [FarmMapCoordinate]) -> MKMapRect? {
            let points = boundary.map {
                MKMapPoint(CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
            }
            guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                  let minY = points.map(\.y).min(), let maxY = points.map(\.y).max(),
                  maxX > minX, maxY > minY else { return nil }
            return MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }

        private static func imageRect(for data: FarmOrthomosaicMapData, inside bounds: MKMapRect) -> MKMapRect? {
            guard data.imagePixelWidth > 0, data.imagePixelHeight > 0,
                  bounds.width > 0, bounds.height > 0 else { return nil }
            let aspect = Double(data.imagePixelWidth) / Double(data.imagePixelHeight)
            if bounds.width / bounds.height > aspect {
                let width = bounds.height * aspect
                return MKMapRect(x: bounds.midX - width / 2, y: bounds.minY, width: width, height: bounds.height)
            }
            let height = bounds.width / aspect
            return MKMapRect(x: bounds.minX, y: bounds.midY - height / 2, width: bounds.width, height: height)
        }

        private static func coordinate(for pixel: PixelPoint, data: FarmOrthomosaicMapData,
                                       rect: MKMapRect) -> CLLocationCoordinate2D? {
            guard data.imagePixelWidth > 0, data.imagePixelHeight > 0 else { return nil }
            let x = rect.minX + pixel.x / Double(data.imagePixelWidth) * rect.width
            let y = rect.minY + pixel.y / Double(data.imagePixelHeight) * rect.height
            return MKMapPoint(x: x, y: y).coordinate
        }

        private static func center(of polygon: [PixelPoint]) -> PixelPoint? {
            guard let minX = polygon.map(\.x).min(), let maxX = polygon.map(\.x).max(),
                  let minY = polygon.map(\.y).min(), let maxY = polygon.map(\.y).max() else { return nil }
            return PixelPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        }

        private static func downsampledImage(at url: URL) -> CGImage? {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 4_096,
                kCGImageSourceShouldCacheImmediately: true
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }

        private static func color(for label: TreeHealthLabel) -> UInt32 {
            switch label {
            case .normal: TreeConditionCategory.normal.colorHex
            case .terindikasi: TreeConditionCategory.terindikasi.colorHex
            case .defisiensi: TreeConditionCategory.defisiensi.colorHex
            case .tidakWajar: TreeConditionCategory.tidakWajar.colorHex
            case .unknown: TreeConditionCategory.unknown.colorHex
            }
        }
    }
}

private final class FertilizingImageOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let image: CGImage

    init(image: CGImage, rect: MKMapRect) {
        self.image = image
        boundingMapRect = rect
        coordinate = MKMapPoint(x: rect.midX, y: rect.midY).coordinate
    }
}

private final class FertilizingImageRenderer: MKOverlayRenderer {
    private let imageOverlay: FertilizingImageOverlay

    init(overlay: FertilizingImageOverlay) {
        imageOverlay = overlay
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let imageRect = rect(for: imageOverlay.boundingMapRect)
        context.saveGState()
        context.interpolationQuality = .high
        // Keep the image's top-left pixel origin aligned with its zone boxes.
        context.translateBy(x: 0, y: imageRect.minY + imageRect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(imageOverlay.image, in: imageRect)
        context.restoreGState()
    }
}

private final class FertilizingZoneAnnotation: NSObject, MKAnnotation {
    let detail: FertilizingZoneDetail
    let coordinate: CLLocationCoordinate2D
    var title: String? { detail.name }
    var subtitle: String? { "\(detail.doseKg.formatted(.number.precision(.fractionLength(0...1)))) kg" }

    init(detail: FertilizingZoneDetail, coordinate: CLLocationCoordinate2D) {
        self.detail = detail
        self.coordinate = coordinate
    }
}

private final class FertilizingUserLocationAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
