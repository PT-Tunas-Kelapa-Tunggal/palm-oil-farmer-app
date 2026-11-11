import SwiftUI

/// SHEET "Cari Lokasi" (step 1 entry point, presented from the garden list).
/// The location guide and search share one sheet and one registration session:
/// `.guide` shows `LocationDiscoveryGuide`, `.search` shows `LocationSearchView`.
struct RegistrationIntroView: View {
    @State private var flow: GardenRegistrationFlow
    @Environment(\.dismiss) private var dismiss
    typealias Step = GardenRegistrationStep

    init(flow: GardenRegistrationFlow) {
        _flow = State(initialValue: flow)
    }

    var body: some View {
        DynamicSheet(animation: .bouncy, size: .large) {
            sheetContent
        }
        .presentationBackgroundInteraction(.disabled)
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
    }

    @ViewBuilder
    private var sheetContent: some View {
        Group {
            switch flow.coordinator.step {
            case .guide:
                LocationDiscoveryGuide(onContinue: flow.coordinator.continueToSearch) {
                    flow.coordinator.cancel()
                    dismiss()
                }
            case .search:
                LocationSearchView(flow: flow)
            }
        }
        .presentationBackground(RegistrationStyle.background)
        .presentationBackgroundInteraction(.disabled)
    }
}

#if DEBUG
#Preview("Sheet Cari Lokasi · 1 Panduan") {
    RegistrationSheetPreview {
        RegistrationIntroView(flow: GardenRegistrationPreview.registrationFlow(step: .guide))
    }
}

#Preview("Sheet Cari Lokasi · 2 Pencarian") {
    RegistrationSheetPreview {
        RegistrationIntroView(flow: GardenRegistrationPreview.registrationFlow(step: .search))
    }
}
#endif
