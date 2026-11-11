import SwiftUI

/// "Cari Lokasi" sheet. The location guide and search share one sheet and one registration session.
struct RegistrationIntroView: View {
    @State private var viewModel: RegistrationIntroViewModel
    @Environment(\.dismiss) private var dismiss
    typealias Step = GardenRegistrationStep

    init(viewModel: RegistrationIntroViewModel) {
        _viewModel = State(initialValue: viewModel)
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
            switch viewModel.step {
            case .guide:
                LocationDiscoveryGuide(onContinue: viewModel.continueToSearch) {
                    viewModel.cancel()
                    dismiss()
                }
            case .search:
                LocationSearchView(viewModel: viewModel)
            }
        }
        .presentationBackground(RegistrationStyle.background)
        .presentationBackgroundInteraction(.disabled)
    }
}

#if DEBUG
#Preview("Sheet Cari Lokasi · 1 Panduan") {
    RegistrationSheetPreview {
        RegistrationIntroView(viewModel: GardenRegistrationPreview.introViewModel(step: .guide))
    }
}

#Preview("Sheet Cari Lokasi · 2 Pencarian") {
    RegistrationSheetPreview {
        RegistrationIntroView(viewModel: GardenRegistrationPreview.introViewModel(step: .search))
    }
}
#endif
