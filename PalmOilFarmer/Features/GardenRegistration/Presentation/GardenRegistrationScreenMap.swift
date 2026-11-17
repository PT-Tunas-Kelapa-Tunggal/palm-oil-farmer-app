import SwiftUI
import UIKit

#if DEBUG
private struct RegistrationScreenFrame<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.bold())
            content()
                .frame(width: 402, height: 874)
                .background(KropsTheme.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 44))
                .overlay { RoundedRectangle(cornerRadius: 44).stroke(KropsTheme.separatorOpaque) }
        }
    }
}

#Preview("Peta Alur Registrasi", traits: .fixedLayout(width: 3100, height: 1000)) {
    ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 40) {
            RegistrationScreenFrame(title: "1a · Panduan Lokasi") {
                LocationDiscoveryGuide(onContinue: {}, onClose: {})
            }
            RegistrationScreenFrame(title: "1b · Cari Lokasi") {
                LocationSearchContentPreview(query: "smkn gunung kijang",
                                             results: GardenRegistrationPreview.searchResults)
            }
            RegistrationScreenFrame(title: "1c · Foto Kebun") {
                VStack(spacing: 0) {
                    RegistrationHeader(title: "Foto Kebun", onClose: {})
                    PhotoSelectionContent(location: GardenRegistrationPreview.photoLocation,
                                          image: UIImage(named: "RegistrationPhotoReference"),
                                          creationDate: Date(timeIntervalSince1970: 1_793_582_040))
                }
            }
            RegistrationScreenFrame(title: "2a · Konfirmasi Lokasi") {
                Color.clear
                    .overlay { Image("RegistrationSearchSatellite").resizable().scaledToFill() }
                    .clipped()
                    .overlay(alignment: .bottom) {
                        LocationConfirmationPanel(location: GardenRegistrationPreview.searchLocation,
                                                  onBack: {}, onContinue: {})
                            .frame(height: 230)
                            .background(KropsTheme.surfaceCard)
                    }
            }
            RegistrationScreenFrame(title: "2b · Batas Kebun") {
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
                        .background(KropsTheme.surfaceCard)
                }
            }
            RegistrationScreenFrame(title: "3a · Data Kebun") {
                GardenDetailsView(viewModel: GardenRegistrationPreview.detailsViewModel(),
                                  referenceMapImage: "RegistrationBoundaryMap", metrics: GardenPreviewData.metrics)
            }
            RegistrationScreenFrame(title: "3b · Kebun Tersimpan") {
                GardenSavedConfirmationView(gardenName: "Belakang rumah", area: "2,3 ha", onContinue: {})
            }
        }
        .padding(40)
    }
}
#endif
