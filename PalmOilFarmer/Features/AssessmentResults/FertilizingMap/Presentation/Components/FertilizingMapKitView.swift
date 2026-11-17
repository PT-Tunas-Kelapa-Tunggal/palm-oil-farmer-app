import ImageIO
import CoreLocation
import MapKit
import SwiftUI
import UIKit

/// Satellite MapKit canvas with the bundled orthomosaic and JSON-derived tree/zone boxes.
@MainActor
struct FertilizingMapKitView: UIViewRepresentable {
    let data: FarmOrthomosaicMapData
    let zones: [FertilizingZoneDetail]
    let mode: AreaDivisionMode
    let wholeFarmDoseText: String
    let selectedZone: FertilizingZoneDetail?
    let onSelectZone: (FertilizingZoneDetail) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.mapType = .satellite
        map.delegate = context.coordinator
        map.isRotateEnabled = true
        map.isPitchEnabled = true
        map.showsUserLocation = true
        context.coordinator.requestLocationAuthorization()
        context.coordinator.update(map, data: data, zones: zones, mode: mode,
                                   wholeFarmDoseText: wholeFarmDoseText,
                                   selectedZone: selectedZone,
                                   onSelectZone: onSelectZone)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.update(map, data: data, zones: zones, mode: mode,
                                   wholeFarmDoseText: wholeFarmDoseText,
                                   selectedZone: selectedZone,
                                   onSelectZone: onSelectZone)
    }

    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate {
        private let locationManager = CLLocationManager()
        private var lastData: FarmOrthomosaicMapData?
        private var lastZones: [FertilizingZoneDetail] = []
        private var lastMode: AreaDivisionMode?
        private var lastWholeFarmDoseText: String?
        private var lastSelectedZoneID: Int?
        private var imageMapRect: MKMapRect?
        private var zoneAnnotations: [ObjectIdentifier: FertilizingZoneDetail] = [:]
        private var onSelectZone: ((FertilizingZoneDetail) -> Void)?

        func requestLocationAuthorization() {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }

        func update(
            _ map: MKMapView,
            data: FarmOrthomosaicMapData,
            zones: [FertilizingZoneDetail],
            mode: AreaDivisionMode,
            wholeFarmDoseText: String,
            selectedZone: FertilizingZoneDetail?,
            onSelectZone: @escaping (FertilizingZoneDetail) -> Void
        ) {
            self.onSelectZone = onSelectZone
            let selectedZoneID = selectedZone?.id
            guard lastData != data || lastZones != zones || lastMode != mode
                    || lastWholeFarmDoseText != wholeFarmDoseText
                    || lastSelectedZoneID != selectedZoneID else { return }

            let shouldReframe = lastData != data || lastMode != mode
            lastData = data
            lastZones = zones
            lastMode = mode
            lastWholeFarmDoseText = wholeFarmDoseText
            lastSelectedZoneID = selectedZoneID

            map.removeOverlays(map.overlays)
            map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
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
                let boundaryCoordinates = data.farmBoundary.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                }
                if boundaryCoordinates.count >= 3 {
                    let boundary = MKPolygon(coordinates: boundaryCoordinates, count: boundaryCoordinates.count)
                    boundary.title = "farm-boundary"
                    map.addOverlay(boundary, level: .aboveLabels)
                }
                let center = MKMapPoint(x: farmRect.midX, y: farmRect.midY).coordinate
                map.addAnnotation(FertilizingWholeFarmAnnotation(doseText: wholeFarmDoseText, coordinate: center))
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
            if polygon.title == "farm-boundary" {
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.95)
                renderer.fillColor = .clear
                renderer.lineWidth = 2.5
            } else if polygon.title?.hasPrefix("tree-") == true {
                let treeID = Int64(polygon.title?.replacingOccurrences(of: "tree-", with: "") ?? "") ?? 0
                let label = lastData?.trees.first(where: { $0.id == treeID })?.healthynessLabel ?? .unknown
                let tint = Self.color(for: label)
                renderer.strokeColor = tint.withAlphaComponent(0.95)
                renderer.fillColor = tint.withAlphaComponent(0.42)
                renderer.lineWidth = 1.2
            } else {
                let zoneID = Int64(polygon.title?.replacingOccurrences(of: "zone-", with: "") ?? "") ?? 0
                let isSelected = Int64(lastSelectedZoneID ?? -1) == zoneID
                renderer.strokeColor = UIColor.white.withAlphaComponent(isSelected ? 1 : 0.92)
                renderer.fillColor = isSelected ? UIColor.white.withAlphaComponent(0.10) : .clear
                renderer.lineWidth = isSelected ? 3 : 2
            }
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let wholeFarm = annotation as? FertilizingWholeFarmAnnotation {
                let reuseID = "fertilizing-whole-farm"
                let label = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? FertilizingZoneAnnotationView)
                    ?? FertilizingZoneAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                label.annotation = annotation
                label.configure(name: "Seluruh Kebun", doseText: wholeFarm.doseText)
                return label
            }

            guard let zone = annotation as? FertilizingZoneAnnotation else { return nil }
            let reuseID = "fertilizing-zone"
            let label = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? FertilizingZoneAnnotationView)
                ?? FertilizingZoneAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            label.annotation = annotation
            label.configure(
                name: zone.detail.name,
                doseText: "\(zone.detail.doseKg.formatted(.number.precision(.fractionLength(0...1)))) kg"
            )
            return label
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
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)?
                .removingBlackNoData()
        }

        private static func color(for label: TreeHealthLabel) -> UIColor {
            switch label {
            case .normal: UIColor(TreeConditionCategory.normal.color)
            case .terindikasi: UIColor(TreeConditionCategory.terindikasi.color)
            case .defisiensi: UIColor(TreeConditionCategory.defisiensi.color)
            case .tidakWajar: UIColor(TreeConditionCategory.tidakWajar.color)
            case .unknown: UIColor(TreeConditionCategory.unknown.color)
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

private final class FertilizingZoneAnnotationView: MKAnnotationView {
    private let nameLabel = UILabel()
    private let doseLabel = UILabel()
    private let labels = UIStackView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 112, height: 48)
        centerOffset = .zero
        canShowCallout = false
        displayPriority = .required

        labels.axis = .vertical
        labels.alignment = .center
        labels.spacing = 0
        labels.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labels)

        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        doseLabel.font = .systemFont(ofSize: 19, weight: .bold)
        [nameLabel, doseLabel].forEach {
            $0.textColor = .white
            $0.textAlignment = .center
            $0.shadowColor = UIColor.black.withAlphaComponent(0.9)
            $0.shadowOffset = CGSize(width: 0, height: 1)
            $0.layer.shadowOpacity = 1
            $0.layer.shadowRadius = 3
        }
        labels.addArrangedSubview(nameLabel)
        labels.addArrangedSubview(doseLabel)
        NSLayoutConstraint.activate([
            labels.centerXAnchor.constraint(equalTo: centerXAnchor),
            labels.centerYAnchor.constraint(equalTo: centerYAnchor),
            labels.widthAnchor.constraint(equalTo: widthAnchor),
            labels.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(name: String, doseText: String) {
        nameLabel.text = name
        doseLabel.text = doseText
    }
}

private final class FertilizingWholeFarmAnnotation: NSObject, MKAnnotation {
    let doseText: String
    let coordinate: CLLocationCoordinate2D
    var title: String? { "Seluruh Kebun" }
    var subtitle: String? { doseText }

    init(doseText: String, coordinate: CLLocationCoordinate2D) {
        self.doseText = doseText
        self.coordinate = coordinate
    }
}


#if DEBUG
#Preview("Fertilizing Map · Per Zona") {
    let fixture = DummyFarmGreenIndexFixture.makeItem()
    if let mapData = fixture.orthomosaic {
        let zones = mapData.zones.map { zone in
            let minX = zone.boundingBox.map(\.x).min() ?? 0
            let maxX = zone.boundingBox.map(\.x).max() ?? 0
            let minY = zone.boundingBox.map(\.y).min() ?? 0
            let maxY = zone.boundingBox.map(\.y).max() ?? 0
            return FertilizingZoneDetail(
                id: Int(zone.id),
                name: "Zona \(zone.id)",
                doseKg: 25,
                relativeX: CGFloat((minX + maxX) / 2 / Double(max(mapData.imagePixelWidth, 1))),
                relativeY: CGFloat((minY + maxY) / 2 / Double(max(mapData.imagePixelHeight, 1)))
            )
        }

        FertilizingMapKitView(
            data: mapData,
            zones: zones,
            mode: .perZona,
            wholeFarmDoseText: "400 kg",
            selectedZone: zones.first,
            onSelectZone: { _ in }
        )
        .ignoresSafeArea()
        .frame(height: 760)
    } else {
        ContentUnavailableView("Peta contoh tidak tersedia", systemImage: "map")
    }
}
#endif
