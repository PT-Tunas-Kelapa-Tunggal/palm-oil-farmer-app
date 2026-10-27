#if DEBUG
import SwiftUI

/// Tap Daftarkan Kebun in Canvas to inspect each native sheet interactively.
struct GlassSheetFlowPreview: View {
    enum Screen {
        case guide, photo, address, search, details, plantingDate
    }

    let screen: Screen
    @State private var isPresented = false

    var body: some View {
        GardenListScreen(onRegisterGarden: { isPresented = true })
            .sheet(isPresented: $isPresented) {
                switch screen {
                case .guide:
                    RegistrationFlow(onLocate: { _ in })
                case .photo:
                    RegistrationFlow(initialStep: .photo, onLocate: { _ in })
                case .address:
                    RegistrationFlow(initialStep: .address, onLocate: { _ in })
                case .search:
                    LocationSearchScreen(initialResults: [], onSelect: { _ in })
                case .details:
                    GardenDetailsScreen(
                        location: GardenPreviewData.location, boundary: GardenPreviewData.boundary,
                        onSave: { _ in true }, referenceMapImage: "GardenBoundaryMap",
                        metrics: GardenPreviewData.metrics
                    )
                case .plantingDate:
                    PlantingDatePickerScreen(onConfirm: { _, _ in })
                }
            }
    }
}

#Preview("Glass · Panduan · Native Sheet") { GlassSheetFlowPreview(screen: .guide) }
#Preview("Glass · Foto · Native Sheet") { GlassSheetFlowPreview(screen: .photo) }
#Preview("Glass · Alamat · Native Sheet") { GlassSheetFlowPreview(screen: .address) }
#Preview("Glass · Pencarian · Native Sheet") { GlassSheetFlowPreview(screen: .search) }
#Preview("Glass · Data Kebun · Native Sheet") { GlassSheetFlowPreview(screen: .details) }
#Preview("Glass · Tahun Tanam · Native Sheet") { GlassSheetFlowPreview(screen: .plantingDate) }
#endif
