import CoreLocation
import ImageIO
import MapKit
import SwiftUI
import UIKit

/// Assessment map image and compact zone markers share one MapKit coordinate space.
struct SpreaderAssessmentMapKitView: UIViewRepresentable {
    let data: FarmOrthomosaicMapData
    let zones: [WaypointZone]
    let currentZoneID: Int?
    let fix: CLLocation?
    @Binding var camera: MapCameraPosition
    let cameraRequestID: Int
    @Binding var followsUser: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.mapType = .satellite
        map.isPitchEnabled = false
        map.isRotateEnabled = true
        map.delegate = context.coordinator
        context.coordinator.update(
            map, data: data, zones: zones,
            currentZoneID: currentZoneID, fix: fix, camera: camera,
            cameraRequestID: cameraRequestID, followsUser: $followsUser
        )
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.update(
            map, data: data, zones: zones,
            currentZoneID: currentZoneID, fix: fix, camera: camera,
            cameraRequestID: cameraRequestID, followsUser: $followsUser
        )
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        private enum CameraRequest: Equatable {
            case rect(Double, Double, Double, Double)
            case region(Double, Double, Double, Double)
        }

        private var lastData: FarmOrthomosaicMapData?
        private var lastZoneIDs: [Int] = []
        private var lastCurrentZoneID: Int?
        private var lastFixCoordinate: CLLocationCoordinate2D?
        private var zoneAnnotations: [Int: SpreaderZoneAnnotation] = [:]
        private var locationAnnotation: SpreaderLocationAnnotation?
        private var lastCameraRequest: CameraRequest?
        private var lastCameraRequestID: Int?
        private var isApplyingCamera = false
        private var followsUser: Binding<Bool>?

        func update(
            _ map: MKMapView,
            data: FarmOrthomosaicMapData,
            zones: [WaypointZone],
            currentZoneID: Int?,
            fix: CLLocation?,
            camera: MapCameraPosition,
            cameraRequestID: Int,
            followsUser: Binding<Bool>
        ) {
            self.followsUser = followsUser

            if lastData != data {
                lastData = data
                map.removeOverlays(map.overlays)
                lastZoneIDs = []
                if let imageRect = Self.imageRect(for: data),
                   let image = data.imageURL.flatMap(Self.downsampledImage(at:)) {
                    map.addOverlay(SpreaderImageOverlay(image: image, rect: imageRect), level: .aboveLabels)
                }
            }

            let zoneIDs = zones.map(\.id)
            if zoneIDs != lastZoneIDs {
                lastZoneIDs = zoneIDs
                lastCurrentZoneID = nil
                map.removeOverlays(map.overlays.filter { $0 is MKPolygon })
                let polygons = zones.flatMap { zone in
                    zone.fragments.compactMap { fragment -> MKPolygon? in
                        guard fragment.count >= 3 else { return nil }
                        let polygon = MKPolygon(coordinates: fragment, count: fragment.count)
                        polygon.title = "zone-\(zone.id)"
                        return polygon
                    }
                }
                map.addOverlays(polygons, level: .aboveLabels)
                map.removeAnnotations(Array(zoneAnnotations.values))
                zoneAnnotations.removeAll()
                for zone in zones {
                    let annotation = SpreaderZoneAnnotation(id: zone.id, coordinate: zone.destination)
                    zoneAnnotations[zone.id] = annotation
                    map.addAnnotation(annotation)
                }
            }

            if lastCurrentZoneID != currentZoneID {
                lastCurrentZoneID = currentZoneID
                for annotation in zoneAnnotations.values {
                    annotation.isCurrent = annotation.zoneID == currentZoneID
                    (map.view(for: annotation) as? SpreaderZoneAnnotationView)?.configure(annotation)
                }
            }

            let coordinate = fix?.coordinate
            if coordinate?.latitude != lastFixCoordinate?.latitude
                || coordinate?.longitude != lastFixCoordinate?.longitude {
                lastFixCoordinate = coordinate
                if let locationAnnotation { map.removeAnnotation(locationAnnotation) }
                if let coordinate {
                    let annotation = SpreaderLocationAnnotation(coordinate: coordinate)
                    locationAnnotation = annotation
                    map.addAnnotation(annotation)
                } else {
                    locationAnnotation = nil
                }
            }

            let request: CameraRequest?
            if let rect = camera.rect {
                request = .rect(rect.minX, rect.minY, rect.width, rect.height)
            } else if let region = camera.region {
                request = .region(
                    region.center.latitude, region.center.longitude,
                    region.span.latitudeDelta, region.span.longitudeDelta
                )
            } else {
                request = nil
            }
            if request != lastCameraRequest || cameraRequestID != lastCameraRequestID {
                lastCameraRequest = request
                lastCameraRequestID = cameraRequestID
                isApplyingCamera = true
                switch request {
                case let .rect(x, y, width, height):
                    map.setVisibleMapRect(
                        MKMapRect(x: x, y: y, width: width, height: height),
                        animated: false
                    )
                case let .region(latitude, longitude, latitudeDelta, longitudeDelta):
                    map.setRegion(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
                        ),
                        animated: false
                    )
                case nil:
                    isApplyingCamera = false
                }
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let image = overlay as? SpreaderImageOverlay {
                return SpreaderImageRenderer(overlay: image)
            }
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.85)
                renderer.fillColor = .clear
                renderer.lineWidth = 1.1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let zone = annotation as? SpreaderZoneAnnotation {
                let reuseID = "spreader-zone"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? SpreaderZoneAnnotationView)
                    ?? SpreaderZoneAnnotationView(annotation: zone, reuseIdentifier: reuseID)
                view.annotation = zone
                view.configure(zone)
                return view
            }
            if annotation is SpreaderLocationAnnotation {
                let reuseID = "spreader-location"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                view.annotation = annotation
                view.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                view.layer.cornerRadius = 12
                view.layer.borderWidth = 3
                view.layer.borderColor = UIColor.white.cgColor
                view.backgroundColor = UIColor.systemOrange
                view.displayPriority = .required
                view.accessibilityLabel = "Posisi Anda"
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            if !isApplyingCamera, followsUser?.wrappedValue == true {
                DispatchQueue.main.async { [weak self] in self?.followsUser?.wrappedValue = false }
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isApplyingCamera = false
        }

        private static func imageRect(for data: FarmOrthomosaicMapData) -> MKMapRect? {
            guard data.imagePixelWidth > 0, data.imagePixelHeight > 0 else { return nil }
            let points = data.farmBoundary.map {
                MKMapPoint(CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
            }
            guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                  let minY = points.map(\.y).min(), let maxY = points.map(\.y).max(),
                  maxX > minX, maxY > minY else { return nil }
            let bounds = MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            let aspect = Double(data.imagePixelWidth) / Double(data.imagePixelHeight)
            if bounds.width / bounds.height > aspect {
                let width = bounds.height * aspect
                return MKMapRect(x: bounds.midX - width / 2, y: bounds.minY, width: width, height: bounds.height)
            }
            let height = bounds.width / aspect
            return MKMapRect(x: bounds.minX, y: bounds.midY - height / 2, width: bounds.width, height: height)
        }

        private static func downsampledImage(at url: URL) -> CGImage? {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 4_096,
                kCGImageSourceShouldCacheImmediately: true
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)?
                .removingBlackNoData()
        }
    }
}

private final class SpreaderImageOverlay: NSObject, MKOverlay {
    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let image: CGImage

    init(image: CGImage, rect: MKMapRect) {
        self.image = image
        boundingMapRect = rect
        coordinate = MKMapPoint(x: rect.midX, y: rect.midY).coordinate
    }
}

private final class SpreaderImageRenderer: MKOverlayRenderer {
    private let imageOverlay: SpreaderImageOverlay

    init(overlay: SpreaderImageOverlay) {
        imageOverlay = overlay
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let imageRect = rect(for: imageOverlay.boundingMapRect)
        context.saveGState()
        context.interpolationQuality = .high
        context.translateBy(x: 0, y: imageRect.minY + imageRect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(imageOverlay.image, in: imageRect)
        context.restoreGState()
    }
}

private final class SpreaderZoneAnnotation: NSObject, MKAnnotation {
    let zoneID: Int
    let coordinate: CLLocationCoordinate2D
    var isCurrent = false
    var title: String? { "Z\(zoneID)" }

    init(id: Int, coordinate: CLLocationCoordinate2D) {
        zoneID = id
        self.coordinate = coordinate
    }
}

private final class SpreaderZoneAnnotationView: MKAnnotationView {
    private let label = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 28, height: 22)
        centerOffset = .zero
        layer.cornerRadius = 11
        displayPriority = .required
        canShowCallout = false
        label.frame = bounds
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ zone: SpreaderZoneAnnotation) {
        label.text = "Z\(zone.zoneID)"
        backgroundColor = UIColor.black.withAlphaComponent(zone.isCurrent ? 0.85 : 0.65)
        accessibilityLabel = "Zona \(zone.zoneID)"
    }
}

private final class SpreaderLocationAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    var title: String? { "Posisi Anda" }

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
