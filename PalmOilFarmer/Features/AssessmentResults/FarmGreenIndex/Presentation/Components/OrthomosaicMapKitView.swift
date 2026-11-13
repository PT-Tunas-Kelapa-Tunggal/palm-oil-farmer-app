import MapKit
import SwiftUI
import ImageIO
import UIKit

/// Displays the CloudKit orthomosaic in its farm boundary's geographic bounding rectangle.
@MainActor
struct OrthomosaicMapKitView: UIViewRepresentable {
    let data: FarmOrthomosaicMapData
    let pins: [TreePinItem]
    let selectedPin: TreePinItem?
    let showsZones: Bool
    let showsTrees: Bool
    let onSelectPin: (TreePinItem) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.mapType = .satellite
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        let treeTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTreeTap(_:)))
        treeTap.delegate = context.coordinator
        treeTap.cancelsTouchesInView = false
        mapView.addGestureRecognizer(treeTap)
        context.coordinator.update(mapView, data: data, pins: pins, selectedPin: selectedPin,
                                   showsZones: showsZones, showsTrees: showsTrees, onSelectPin: onSelectPin)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.update(mapView, data: data, pins: pins, selectedPin: selectedPin,
                                   showsZones: showsZones, showsTrees: showsTrees, onSelectPin: onSelectPin)
    }

    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        private var lastData: FarmOrthomosaicMapData?
        private var lastPins: [TreePinItem] = []
        private var lastShowsZones = false
        private var lastShowsTrees = false
        private var selectedPinID: String?
        private var treeOverlayPins: [ObjectIdentifier: TreePinItem] = [:]
        private var onSelectPin: ((TreePinItem) -> Void)?

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        @objc func handleTreeTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, let mapView = gesture.view as? MKMapView else { return }
            let coordinate = mapView.convert(gesture.location(in: mapView), toCoordinateFrom: mapView)
            let mapPoint = MKMapPoint(coordinate)
            let tappedPin = treeOverlayPins.first { key, _ in
                guard let polygon = mapView.overlays.first(where: { ObjectIdentifier($0) == key }) as? MKPolygon else {
                    return false
                }
                return Self.contains(mapPoint, in: polygon)
            }?.value
            if let tappedPin { onSelectPin?(tappedPin) }
        }

        func update(
            _ mapView: MKMapView,
            data: FarmOrthomosaicMapData,
            pins: [TreePinItem],
            selectedPin: TreePinItem?,
            showsZones: Bool,
            showsTrees: Bool,
            onSelectPin: @escaping (TreePinItem) -> Void
        ) {
            self.onSelectPin = onSelectPin
            let selectionChanged = selectedPinID != selectedPin?.id
            selectedPinID = selectedPin?.id
            guard lastData != data || lastPins != pins || lastShowsZones != showsZones || lastShowsTrees != showsTrees else {
                if selectionChanged {
                    for overlay in mapView.overlays where treeOverlayPins[ObjectIdentifier(overlay)] != nil {
                        mapView.renderer(for: overlay)?.setNeedsDisplay()
                    }
                }
                return
            }
            lastData = data
            lastPins = pins
            lastShowsZones = showsZones
            lastShowsTrees = showsTrees

            mapView.removeOverlays(mapView.overlays)
            mapView.removeAnnotations(mapView.annotations)
            treeOverlayPins.removeAll()

            guard let imageURL = data.imageURL,
                  data.imagePixelWidth > 0, data.imagePixelHeight > 0,
                  data.farmBoundary.count >= 3,
                  let mapRect = Self.mapRect(for: data.farmBoundary),
                  let imageMapRect = Self.imageRect(for: data, inside: mapRect) else { return }

            if let image = Self.downsampledImage(at: imageURL, maxPixelSize: 4_096) {
                mapView.addOverlay(OrthomosaicImageOverlay(image: image, boundingMapRect: imageMapRect), level: .aboveLabels)
            }

            if showsZones {
                let zonePolygons = data.zones.compactMap { zone -> MKPolygon? in
                    polygon(for: zone.boundingBox, data: data, mapRect: imageMapRect, title: "zone-\(zone.id)")
                }
                mapView.addOverlays(zonePolygons, level: .aboveLabels)
                if zonePolygons.isEmpty {
                    let zoneAnnotations = Dictionary(grouping: data.trees, by: \.zoneId).compactMap { entry -> FarmZoneAnnotation? in
                        let (zoneID, trees) = entry
                        let centers = trees.compactMap { Self.center(of: $0.boundingBox) }
                        guard !centers.isEmpty else { return nil }
                        let center = PixelPoint(
                            x: centers.map(\.x).reduce(0, +) / Double(centers.count),
                            y: centers.map(\.y).reduce(0, +) / Double(centers.count)
                        )
                        guard let coordinate = Self.coordinate(for: center, data: data, mapRect: imageMapRect) else { return nil }
                        return FarmZoneAnnotation(zoneID: zoneID, treeCount: trees.count, coordinate: coordinate)
                    }
                    mapView.addAnnotations(zoneAnnotations)
                }
            }

            if showsTrees {
                let pinByID = Dictionary(uniqueKeysWithValues: pins.map { ($0.id, $0) })
                let treePolygons = data.trees.compactMap { tree -> MKPolygon? in
                    guard let pin = pinByID["tree-\(tree.id)"],
                          let polygon = polygon(for: tree.boundingBox, data: data, mapRect: imageMapRect,
                                                title: "tree-\(tree.id)") else { return nil }
                    treeOverlayPins[ObjectIdentifier(polygon)] = pin
                    return polygon
                }
                mapView.addOverlays(treePolygons, level: .aboveLabels)
            }

            mapView.setVisibleMapRect(
                mapRect,
                edgePadding: UIEdgeInsets(top: 130, left: 24, bottom: 300, right: 24),
                animated: false
            )
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let imageOverlay = overlay as? OrthomosaicImageOverlay {
                return OrthomosaicImageRenderer(overlay: imageOverlay)
            }
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                if let pin = treeOverlayPins[ObjectIdentifier(polygon)] {
                    let categoryColor = UIColor(hex: pin.category.colorHex)
                    renderer.strokeColor = categoryColor.withAlphaComponent(0.98)
                    renderer.fillColor = UIColor(hex: pin.category.colorHex).withAlphaComponent(0.58)
                    renderer.lineWidth = pin.id == selectedPinID ? 2.5 : 1.5
                } else {
                    renderer.strokeColor = UIColor.systemTeal.withAlphaComponent(0.9)
                    renderer.fillColor = UIColor.systemTeal.withAlphaComponent(0.12)
                    renderer.lineWidth = 2
                }
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let zone = annotation as? FarmZoneAnnotation else { return nil }
            let reuseID = "farm-zone"
            let marker = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView)
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            marker.annotation = annotation
            marker.canShowCallout = true
            marker.glyphText = "Z\(zone.zoneID)"
            marker.markerTintColor = .systemTeal
            marker.displayPriority = .required
            return marker
        }

        private func polygon(for points: [PixelPoint], data: FarmOrthomosaicMapData,
                             mapRect: MKMapRect, title: String) -> MKPolygon? {
            let coordinates = points.compactMap { Self.coordinate(for: $0, data: data, mapRect: mapRect) }
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

        /// Fits the orthomosaic inside the farm's geographic bounds without distorting its pixel aspect ratio.
        private static func imageRect(for data: FarmOrthomosaicMapData, inside bounds: MKMapRect) -> MKMapRect? {
            guard data.imagePixelWidth > 0, data.imagePixelHeight > 0,
                  bounds.width > 0, bounds.height > 0 else { return nil }
            let imageAspect = Double(data.imagePixelWidth) / Double(data.imagePixelHeight)
            let boundsAspect = bounds.width / bounds.height
            if boundsAspect > imageAspect {
                let width = bounds.height * imageAspect
                return MKMapRect(x: bounds.midX - width / 2, y: bounds.minY, width: width, height: bounds.height)
            }
            let height = bounds.width / imageAspect
            return MKMapRect(x: bounds.minX, y: bounds.midY - height / 2, width: bounds.width, height: height)
        }

        private static func downsampledImage(at url: URL, maxPixelSize: Int) -> CGImage? {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                kCGImageSourceShouldCacheImmediately: true
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }

        private static func center(of points: [PixelPoint]) -> PixelPoint? {
            guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                  let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return nil }
            return PixelPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        }

        private static func contains(_ point: MKMapPoint, in polygon: MKPolygon) -> Bool {
            let vertices = polygon.points()
            guard polygon.pointCount >= 3 else { return false }
            var isInside = false
            var previousIndex = polygon.pointCount - 1
            for currentIndex in 0..<polygon.pointCount {
                let current = vertices[currentIndex]
                let previous = vertices[previousIndex]
                let crosses = (current.y > point.y) != (previous.y > point.y)
                if crosses {
                    let crossingX = (previous.x - current.x) * (point.y - current.y)
                        / (previous.y - current.y) + current.x
                    if point.x < crossingX { isInside.toggle() }
                }
                previousIndex = currentIndex
            }
            return isInside
        }

        private static func coordinate(for point: PixelPoint, data: FarmOrthomosaicMapData,
                                       mapRect: MKMapRect) -> CLLocationCoordinate2D? {
            guard data.imagePixelWidth > 0, data.imagePixelHeight > 0 else { return nil }
            let x = mapRect.minX + point.x / Double(data.imagePixelWidth) * mapRect.width
            let y = mapRect.minY + point.y / Double(data.imagePixelHeight) * mapRect.height
            return MKMapPoint(x: x, y: y).coordinate
        }
    }
}

private final class OrthomosaicImageOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let image: CGImage

    init(image: CGImage, boundingMapRect: MKMapRect) {
        self.image = image
        self.boundingMapRect = boundingMapRect
        coordinate = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY).coordinate
    }
}

private final class OrthomosaicImageRenderer: MKOverlayRenderer {
    private let imageOverlay: OrthomosaicImageOverlay

    init(overlay: OrthomosaicImageOverlay) {
        imageOverlay = overlay
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let imageRect = rect(for: imageOverlay.boundingMapRect)
        context.saveGState()
        context.interpolationQuality = .high
        // MapKit's renderer context has an inverted vertical axis relative to
        // the top-left-origin pixels used by the orthomosaic and its JSON boxes.
        context.translateBy(x: 0, y: imageRect.minY + imageRect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(imageOverlay.image, in: imageRect)
        context.restoreGState()
    }
}

private final class FarmZoneAnnotation: NSObject, MKAnnotation {
    let zoneID: Int64
    let treeCount: Int
    let coordinate: CLLocationCoordinate2D
    var title: String? { "Zona \(zoneID)" }
    var subtitle: String? { "\(treeCount) pohon" }

    init(zoneID: Int64, treeCount: Int, coordinate: CLLocationCoordinate2D) {
        self.zoneID = zoneID
        self.treeCount = treeCount
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
