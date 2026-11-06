#if DEBUG
import SwiftUI

/// Full-screen compositions reuse the production UI, with fixed Sketch map data for comparison.
struct RegistrationFramePreview: View {
    enum Frame: Hashable {
        case guide, photo, address
    }

    let step: Frame
    var selectedLocation: GardenLocation? = nil
    var body: some View {
        GardenListView(onRegisterGarden: {})
            .overlay(alignment: .bottom) {
                Group {
                    if step == .guide {
                        RegistrationIntroView(onLocate: { _ in })
                            .frame(height: 412)
                    } else {
                        LocationSearchView(initialQuery: selectedLocation?.name ?? "",
                                           initialResults: selectedLocation.map { [$0] } ?? [],
                                           onSelect: { _ in })
                            .frame(height: 816)
                    }
                }
                .id(step)
                .background { SheetGlassBackground() }
                .overlay(alignment: .top) {
                    Capsule().fill(.secondary.opacity(0.5)).frame(width: 60, height: 4).padding(.top, 5)
                }
                .padding(.horizontal, step == .guide ? 8 : 0)
                .padding(.bottom, -34)
            }
    }
}

struct SearchFramePreview: View {
    var query = ""
    var body: some View {
        GardenListView(onRegisterGarden: {})
            .overlay(alignment: .bottom) {
                LocationSearchView(initialQuery: query,
                                   initialResults: query.isEmpty ? [] : [GardenPreviewData.location],
                                   onSelect: { _ in })
                    .id(query)
                    .frame(height: 816)
                    .background { SheetGlassBackground() }
                    .padding(.bottom, -34)
            }
    }
}

struct PhotoPickerFramePreview: View {
    var body: some View {
        GardenPhotoPickerView(onSelect: { _ in })
    }
}

enum BoundaryFrameState {
    case region, empty, partial, complete
}

struct BoundaryFramePreview: View {
    let state: BoundaryFrameState

    private var boundary: GardenBoundary {
        state == .region || state == .empty ? GardenBoundary() : GardenPreviewData.boundary
    }

    var body: some View {
        BoundaryEditorLayout(
            boundary: boundary,
            metrics: boundary.points.isEmpty ? GardenDisplayMetrics(area: "0 ha", perimeter: "0 m") : GardenPreviewData.metrics,
            onClose: {}, onSearch: {}, onUndo: {}, onClear: {}, onConfirm: {}
        ) {
            BoundaryReferenceMap(state: state).id(String(describing: state))
        }
    }
}

/// Only the map imagery and coordinates are fixed; controls remain the production SwiftUI views.
private struct BoundaryReferenceMap: View {
    let state: BoundaryFrameState

    private var vertices: [CGPoint] {
        let normalized = [
            CGPoint(x: 1, y: 0.1092665), CGPoint(x: 0.6447475, y: 0),
            CGPoint(x: 0.5567765, y: 0.1550543), CGPoint(x: 0.2097751, y: 0.0379136),
            CGPoint(x: 0, y: 0.5009837), CGPoint(x: 0.3490889, y: 0.6407244),
            CGPoint(x: 0.2322245, y: 0.8789587), CGPoint(x: 0.5, y: 1)
        ]
        let offset = state == .partial ? CGPoint(x: -172.5, y: -864.94) : CGPoint(x: -152.5, y: -867.94)
        let points = normalized.map {
            CGPoint(x: 241 + $0.x * 228.8165 + offset.x, y: 1182.591 + $0.y * 269.593 + offset.y)
        }
        return state == .partial ? Array(points.prefix(5)) : points
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 402
            ZStack(alignment: .topLeading) {
                satellite
                    .frame(width: geometry.size.width, height: geometry.size.height)

                if state == .partial || state == .complete {
                    let points = vertices.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
                    Path { path in
                        path.addLines(points)
                        if state == .complete { path.closeSubpath() }
                    }
                    .fill(.white.opacity(0.25))
                    Path { path in
                        path.addLines(points)
                        if state == .complete { path.closeSubpath() }
                    }
                    .stroke(.white.opacity(0.85), lineWidth: 2)

                    let pinIndexes = state == .partial ? [0, 1, 2, 3, 4] : [0, 1, 2, 3, 4, 6, 7]
                    ForEach(pinIndexes.indices, id: \.self) { index in
                        let point = points[pinIndexes[index]]
                        BoundaryPointMarker(number: index + 1)
                            .position(x: point.x, y: point.y - 14)
                    }
                    let labels = ["238 m", "112 m", "265 m", "328 m", "328 m", "276 m", "193 m", "843 m"]
                    ForEach(0..<(state == .partial ? 4 : points.count), id: \.self) { index in
                        let first = points[index]
                        let second = points[(index + 1) % points.count]
                        Text(labels[index])
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .background(.black.opacity(0.75), in: Capsule())
                            .position(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
                    }
                } else {
                    Circle().fill(.white).frame(width: 28, height: 28)
                        .padding(10).background(.white.opacity(0.4), in: Circle())
                        .padding(8).background(.white.opacity(0.2), in: Circle())
                        .position(x: (state == .region ? 247 : 197) * scale,
                                  y: (state == .region ? 376 : 437) * scale)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .overlay(alignment: .top) {
                LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 185)
            }
        }
    }

    private var satellite: some View {
        let image: String = switch state {
        case .region: "RegionSatelliteSource"
        case .empty: "EmptySatelliteSource"
        case .partial: "MappingSatelliteSource"
        case .complete: "CompleteSatelliteSource"
        }
        return Image(image).resizable().scaledToFill()
    }
}

#Preview("02 · Panduan · Full Frame") {
    RegistrationFramePreview(step: .guide)
}
#Preview("03 · Lokasi dari Foto · Full Frame") {
    RegistrationFramePreview(step: .photo)
}
#Preview("04 · Pilih Foto · Sistem") {
    PhotoPickerFramePreview()
}
#Preview("08 · Cari Kabupaten · Full Frame") {
    SearchFramePreview()
}
#Preview("09 · Kabupaten Terisi · Full Frame") {
    SearchFramePreview(query: "Dumai")
}
#Preview("10 · Kabupaten Terpilih · Full Frame") {
    RegistrationFramePreview(step: .address, selectedLocation: GardenPreviewData.location)
}
#Preview("11 · Peta Kabupaten · Reference") {
    BoundaryFramePreview(state: .region)
}
#Preview("12 · Batas Awal · Reference") {
    BoundaryFramePreview(state: .empty)
}
#Preview("12 Copy · Batas Sebagian · Reference") {
    BoundaryFramePreview(state: .partial)
}
#Preview("12 Copy 2 · Batas Lengkap · Reference") {
    BoundaryFramePreview(state: .complete)
}
#endif
