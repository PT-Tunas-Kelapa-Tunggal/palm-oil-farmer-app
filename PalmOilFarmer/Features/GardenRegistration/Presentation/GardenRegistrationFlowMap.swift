import SwiftUI
import UIKit

// MARK: - Where is what? (GardenRegistration)
//
// Open this file's canvas ("Peta Alur Registrasi") to see the whole flow at once.
// Every view file below also has its own #Preview next to the code.
//
// Domain/                      (1) protocols + (4) models, pure Foundation
//   GardenLocationRepository, GardenPhotoRepository, GardenLocationAuthorizing,
//   GardenRegistrationSaving, GardenPhoto, GardenDetails
// Data/                        (2) repositories + (3) mappers, the only place with MapKit / Photos / CoreLocation
//   Repositories/  GardenRegistrationRepository (saves via Core/Gardens), MapKitGardenLocationRepository,
//                  PhotosGardenPhotoRepository, MappingLocationAuthorization
//   Mappers/       GardenLocationMapper (MKMapItem → GardenLocation), GardenPhotoMapper (PHAsset → GardenPhoto)
//   Services/      LocationSearchService, CurrentLocationProvider
//   Dummy/         Dummy* repositories, only wired up by PreviewSupport (DEBUG only)
// Presentation/
//   Components/    shared by all steps: RegistrationHeader, RegistrationIconButton,
//                  RegistrationPrimaryButton, RegistrationStyle
//
//   1. FindLocation/            GardenRegistrationCoordinator, GardenRegistrationFlow
//      Screens/   RegistrationIntroView ........ SHEET "Cari Lokasi" (guide ↔ search)
//                 LocationSearchView ........... content of that sheet, step .search
//                 GardenPhotoPickerView ........ SHEET "Foto" (gallery → photo preview)
//      Components/ LocationDiscoveryGuide, LocationSearchContent, LocationOptionRow,
//                  CameraPhotoThumbnail, PhotoSelectionContent, PhotoLocationMarker, PhotoLocationCard
//
//   2. SetBoundaries/           GardenMappingCoordinator, GardenMappingFlow
//      Screens/   GardenBoundaryView ........... FULL SCREEN map + one bottom sheet
//                 BoundaryDrawingGuideView ..... standalone guide (not used in production)
//      Sheets/    LocationConfirmationPanel .... bottom sheet, stage .location
//                 BoundaryDrawingGuideSheet .... bottom sheet, stage .guide
//                 BoundaryEditingPanel ......... bottom sheet, stage .drawing
//                 MapBottomPanel ............... layout used inside those sheets
//      Components/ BoundaryEditorLayout, BoundaryMetricsView, BoundaryDrawingGuideDemo,
//                  BoundaryDrawingGuideLayout, BoundaryGeometryMapContent
//      MapMarkers/ RegistrationLocationPin, RegistrationSelectedLocationMarker,
//                  RegistrationUserLocationMarker, RegistrationBoundaryMarker
//
//   3. CompleteInformation/     GardenDetailsCoordinator, GardenDetailsFlow
//      Screens/   GardenDetailsView ............ SHEET "Data Kebun" / "Edit Kebun"
//                 GardenSavedConfirmationView .. FULL SCREEN "Kebun Tersimpan"
//      Sheets/    PlantingDatePickerView ....... SHEET "Tahun Tanam"
//      Components/ RegistrationFormField
//
// Wiring (outside the feature): App/RegistrationComposition, App/MappingComposition (production),
// PreviewSupport/Fixtures/GardenRegistrationPreview + PreviewSupport/SheetPreview (canvas).

#if DEBUG
private struct RegistrationFlowFrame<Content: View>: View {
    let title: String
    let file: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.bold())
            Text(file).font(.caption.monospaced()).foregroundStyle(.secondary)
            content()
                .frame(width: 402, height: 874)
                .background(RegistrationStyle.background)
                .clipShape(RoundedRectangle(cornerRadius: 44))
                .overlay { RoundedRectangle(cornerRadius: 44).stroke(Color(uiColor: .separator)) }
        }
    }
}

#Preview("Peta Alur Registrasi", traits: .fixedLayout(width: 3100, height: 1000)) {
    ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 40) {
            RegistrationFlowFrame(title: "1a · Panduan Lokasi",
                                  file: "FindLocation/Components/LocationDiscoveryGuide") {
                LocationDiscoveryGuide(onContinue: {}, onClose: {})
            }
            RegistrationFlowFrame(title: "1b · Cari Lokasi",
                                  file: "FindLocation/Components/LocationSearchContent") {
                LocationSearchContentPreview(query: "smkn gunung kijang",
                                             results: GardenRegistrationPreview.searchResults)
            }
            RegistrationFlowFrame(title: "1c · Foto Kebun",
                                  file: "FindLocation/Components/PhotoSelectionContent") {
                VStack(spacing: 0) {
                    RegistrationHeader(title: "Foto Kebun", onClose: {})
                    PhotoSelectionContent(location: GardenRegistrationPreview.photoLocation,
                                          image: UIImage(named: "RegistrationPhotoReference"),
                                          creationDate: Date(timeIntervalSince1970: 1_793_582_040))
                }
            }
            RegistrationFlowFrame(title: "2a · Konfirmasi Lokasi",
                                  file: "SetBoundaries/Sheets/LocationConfirmationPanel") {
                Color.clear
                    .overlay { Image("RegistrationSearchSatellite").resizable().scaledToFill() }
                    .clipped()
                    .overlay(alignment: .bottom) {
                        LocationConfirmationPanel(location: GardenRegistrationPreview.searchLocation,
                                                  onBack: {}, onContinue: {})
                            .frame(height: 230)
                            .background(RegistrationStyle.surface)
                    }
            }
            RegistrationFlowFrame(title: "2b · Batas Kebun",
                                  file: "SetBoundaries/Components/BoundaryEditorLayout") {
                BoundaryEditorLayout(boundary: GardenPreviewData.boundary, metrics: GardenPreviewData.metrics,
                                     showsBottomPanel: false,
                                     onClose: {}, onSearch: {}, onUndo: {}, onClear: {}, onConfirm: {}) {
                    Color.clear
                        .overlay { Image("RegistrationClosedSatellite").resizable().scaledToFill() }
                        .clipped()
                }
                .overlay(alignment: .bottom) {
                    BoundaryEditingPanel(boundary: GardenPreviewData.boundary,
                                         onUndo: {}, onClear: {}, onConfirm: {})
                        .frame(height: 180)
                        .background(RegistrationStyle.surface)
                }
            }
            RegistrationFlowFrame(title: "3a · Data Kebun",
                                  file: "CompleteInformation/Screens/GardenDetailsView") {
                GardenDetailsView(flow: GardenRegistrationPreview.detailsFlow(),
                                  referenceMapImage: "RegistrationBoundaryMap", metrics: GardenPreviewData.metrics)
            }
            RegistrationFlowFrame(title: "3b · Kebun Tersimpan",
                                  file: "CompleteInformation/Screens/GardenSavedConfirmationView") {
                GardenSavedConfirmationView(gardenName: "Belakang rumah", area: "2,3 ha", onContinue: {})
            }
        }
        .padding(40)
    }
}
#endif
