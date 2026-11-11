#if DEBUG
import SwiftUI

/// One entry for each screen on Sketch page COdedUI5. Maps use reference imagery only here.
/// Production headers, panels, fields, and buttons are reused so design edits propagate.
struct CodedUI5Preview: View {
    enum Screen {
        case empty, discovery, searchResults, searchGPS, searchPhoto
        case gallery, selectedPhoto, photoError, searchLocation, currentLocation, photoLocation
        case mappingGuide, mappingEmpty, mappingDrawing, mappingClosed, details, plantingDate, soil
    }

    let screen: Screen
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var location: GardenLocation {
        GardenLocation(
            name: screen == .searchLocation || screen == .searchResults ? "SMKN 1 Gunung Kijang" : "Malang Rapat",
            subtitle: screen == .searchResults ? "Kawal, Gunung Kijang, Bintan"
                : "Jl. Raya Gunung Kijang, Kabupaten Bintan, Kepulauan Riau, Indonesia",
            coordinate: GardenCoordinate(latitude: 1.106115, longitude: 104.119121),
            source: screen == .currentLocation ? .currentLocation : screen == .photoLocation ? .photo : .search
        )
    }

    var body: some View {
        Group {
            switch screen {
            case .empty:
                DashboardStaticView(onRegisterGarden: {})
            case .discovery:
                LocationDiscoveryGuide(onContinue: {}, onClose: {})
            case .searchResults, .searchGPS, .searchPhoto:
                LocationSearchContent(
                    query: $query, isSearchFocused: $searchFocused,
                    results: screen == .searchResults ? [location] : [],
                    onSelect: { _ in }, onCurrentLocation: {}, onPhoto: {}, onClose: {}
                )
                .onAppear { if screen == .searchResults { query = "smkn gunung kijang" } }
            case .gallery:
                VStack(spacing: 0) {
                    RegistrationHeader(title: "Foto", onClose: {})
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4), spacing: 2) {
                            ForEach(0..<32) { _ in
                                Color.white.aspectRatio(1, contentMode: .fit)
                                    .overlay { Image("RegistrationPhotoReference").resizable().scaledToFill() }
                            }
                        }
                    }
                }
            case .selectedPhoto, .photoError:
                VStack(spacing: 0) {
                    RegistrationHeader(title: "Foto Kebun", onClose: {})
                    PhotoSelectionContent(
                        location: screen == .photoError ? nil : location,
                        image: UIImage(named: "RegistrationPhotoReference"),
                        creationDate: Date(timeIntervalSince1970: 1793582040),
                        hasNoLocation: screen == .photoError
                    )
                }
                .safeAreaInset(edge: .bottom) {
                    RegistrationPrimaryButton(title: screen == .photoError ? "Pilih Foto Lain" : "Gunakan Foto Ini", action: {})
                        .padding(16)
                }
            case .searchLocation, .currentLocation, .photoLocation:
                confirmation
            case .mappingGuide:
                referenceMap
                    .ignoresSafeArea()
                    .sheet(isPresented: .constant(true)) {
                        BoundaryDrawingGuideSheet(onContinue: {})
                    }
            case .mappingEmpty, .mappingDrawing, .mappingClosed:
                BoundaryEditorLayout(
                    boundary: screen == .mappingEmpty ? GardenBoundary() : GardenPreviewData.boundary,
                    metrics: GardenDisplayMetrics(area: screen == .mappingEmpty ? "0 ha" : "1,7 ha",
                                                  perimeter: screen == .mappingEmpty ? "0 m" : "540 m"),
                    isClosed: screen == .mappingClosed,
                    onClose: {}, onSearch: {}, onUndo: {}, onClear: {}, onConfirm: {}
                ) { referenceMap }
            case .details, .soil, .plantingDate:
                GardenDetailsView(location: location, boundary: GardenPreviewData.boundary,
                                  onSave: { _ in true }, referenceMapImage: "RegistrationBoundaryMap",
                                  metrics: GardenDisplayMetrics(area: "1,7 ha", perimeter: "540 m"))
                    .sheet(isPresented: .constant(screen == .plantingDate)) {
                        PlantingDatePickerView(onConfirm: { _, _ in })
                    }
            }
        }
        .background(RegistrationStyle.background)
        .environment(\.locale, Locale(identifier: "id_ID"))
    }

    private var confirmation: some View {
        referenceMap
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                if screen == .photoLocation {
                    RegistrationIconButton(symbol: "xmark", label: "Tutup", action: {}).padding(12)
                }
            }
            .sheet(isPresented: .constant(true)) {
                DynamicSheet(animation: .bouncy, size: .small) {
                    LocationConfirmationPanel(location: location, onBack: {}, onContinue: {})
                }
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.hidden)
            }
    }

    private var referenceMap: some View {
        CodedUI5MapReference(screen: screen, location: location)
    }
}

private struct CodedUI5MapReference: View {
    let screen: CodedUI5Preview.Screen
    let location: GardenLocation

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 402
            ZStack(alignment: .topLeading) {
                if screen == .searchLocation {
                    Image("RegistrationSearchSatellite").resizable()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    RegistrationSelectedLocationMarker(name: location.name)
                    .position(x: 205 * scale, y: 317 * scale)
                } else if screen == .photoLocation || screen == .currentLocation {
                    Image(screen == .currentLocation ? "RegistrationCurrentSatellite" : "RegistrationPhotoSatellite").resizable()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    if screen == .photoLocation {
                        PhotoLocationMarker().position(x: 201 * scale, y: 442 * scale)
                    } else {
                        RegistrationUserLocationMarker()
                            .position(x: 201 * scale, y: 256 * scale)
                    }
                } else {
                    let offset = mapOffset
                    Image(mappingImage).resizable()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    if screen == .mappingDrawing || screen == .mappingClosed {
                        boundary(scale: scale, offset: offset)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    private var mappingImage: String {
        switch screen {
        case .mappingDrawing: "RegistrationDrawingSatellite"
        case .mappingClosed: "RegistrationClosedSatellite"
        case .mappingGuide: "RegistrationGuideSatellite"
        default: "RegistrationMappingSatellite"
        }
    }

    private var mapOffset: CGPoint {
        switch screen {
        case .mappingDrawing: CGPoint(x: -388, y: -57)
        case .mappingClosed: CGPoint(x: -369, y: -64)
        case .mappingGuide: CGPoint(x: -345, y: -117)
        default: CGPoint(x: -324, y: -24)
        }
    }

    private func boundary(scale: CGFloat, offset: CGPoint) -> some View {
        let all = [CGPoint(x: 628, y: 343), CGPoint(x: 459, y: 380),
                   CGPoint(x: 510, y: 664), CGPoint(x: 689, y: 664)]
        let points = (screen == .mappingDrawing ? Array(all.prefix(3)) : all)
            .map { CGPoint(x: ($0.x + offset.x) * scale, y: ($0.y + offset.y) * scale) }
        return ZStack(alignment: .topLeading) {
            Path { path in path.addLines(points); path.closeSubpath() }.fill(.white.opacity(0.25))
            Path { path in path.addLines(points); path.closeSubpath() }.stroke(.white, lineWidth: 2)
            ForEach(points.indices, id: \.self) { index in
                RegistrationBoundaryMarker(number: index + 1)
                    .position(x: points[index].x, y: points[index].y - 16)
            }
            ForEach(0..<(screen == .mappingDrawing ? 2 : points.count), id: \.self) { index in
                let first = points[index]
                let second = points[(index + 1) % points.count]
                Text(index.isMultiple(of: 2) ? "125 m" : "265 m")
                    .font(.caption2).foregroundStyle(.white)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(.black.opacity(0.8), in: Capsule())
                    .position(x: (first.x + second.x) / 2, y: (first.y + second.y) / 2)
            }
        }
    }
}

#Preview("01 · COdedUI5 · Kebun Kosong", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUI5Preview(screen: .empty).safeAreaPadding(.top, 62).safeAreaPadding(.bottom, 34)
}
#Preview("02 · COdedUI5 · Temukan Lokasi", traits: .fixedLayout(width: 402, height: 808)) {
    CodedUI5Preview(screen: .discovery).safeAreaPadding(.bottom, 34)
}
#Preview("03 · COdedUI5 · Hasil Pencarian", traits: .fixedLayout(width: 402, height: 816)) {
    CodedUI5Preview(screen: .searchResults).safeAreaPadding(.bottom, 34)
}
#Preview("04 · COdedUI5 · Cari Alamat GPS", traits: .fixedLayout(width: 402, height: 816)) {
    CodedUI5Preview(screen: .searchGPS).safeAreaPadding(.bottom, 34)
}
#Preview("05 · COdedUI5 · Cari Alamat Foto", traits: .fixedLayout(width: 402, height: 816)) {
    CodedUI5Preview(screen: .searchPhoto).safeAreaPadding(.bottom, 34)
}
#Preview("06 · COdedUI5 · Galeri", traits: .fixedLayout(width: 402, height: 808)) {
    CodedUI5Preview(screen: .gallery).safeAreaPadding(.bottom, 34)
}
#Preview("07 · COdedUI5 · Foto Terpilih", traits: .fixedLayout(width: 402, height: 808)) {
    CodedUI5Preview(screen: .selectedPhoto).safeAreaPadding(.bottom, 34)
}
#Preview("08 · COdedUI5 · Konfirmasi Pencarian", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUI5Preview(screen: .searchLocation).safeAreaPadding(.top, 62).safeAreaPadding(.bottom, 34)
}
#Preview("09 · COdedUI5 · Konfirmasi GPS", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUI5Preview(screen: .currentLocation).safeAreaPadding(.top, 62).safeAreaPadding(.bottom, 34)
}
#Preview("10 · COdedUI5 · Konfirmasi Foto", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUI5Preview(screen: .photoLocation).safeAreaPadding(.top, 62).safeAreaPadding(.bottom, 34)
}
#Preview("11 · COdedUI5 · Panduan Batas", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUI5Preview(screen: .mappingGuide).safeAreaPadding(.top, 62).safeAreaPadding(.bottom, 34)
}
#Preview("12 · COdedUI5 · Batas Awal", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUI5Preview(screen: .mappingEmpty).safeAreaPadding(.top, 62).safeAreaPadding(.bottom, 34)
}
#Preview("13 · COdedUI5 · Menggambar Batas", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUI5Preview(screen: .mappingDrawing).safeAreaPadding(.top, 62).safeAreaPadding(.bottom, 34)
}
#Preview("14 · COdedUI5 · Batas Lengkap", traits: .fixedLayout(width: 402, height: 874)) {
    CodedUI5Preview(screen: .mappingClosed).safeAreaPadding(.top, 62).safeAreaPadding(.bottom, 34)
}
#Preview("15 · COdedUI5 · Data Kebun", traits: .fixedLayout(width: 402, height: 812)) {
    CodedUI5Preview(screen: .details).padding(.bottom, 34)
}
#Preview("16 · COdedUI5 · Tahun Tanam", traits: .fixedLayout(width: 402, height: 812)) {
    CodedUI5Preview(screen: .plantingDate).safeAreaPadding(.bottom, 34)
}
#Preview("17 · COdedUI5 · Jenis Tanah", traits: .fixedLayout(width: 402, height: 812)) {
    CodedUI5Preview(screen: .soil).padding(.bottom, 34)
}
#Preview("18 · Foto tanpa lokasi", traits: .fixedLayout(width: 402, height: 812)) {
    CodedUI5Preview(screen: .photoError).safeAreaPadding(.bottom, 34)
}
#endif
