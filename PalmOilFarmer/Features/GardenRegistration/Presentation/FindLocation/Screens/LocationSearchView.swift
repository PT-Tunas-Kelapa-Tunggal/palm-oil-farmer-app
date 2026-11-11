import SwiftUI

/// Content of the "Cari Lokasi" sheet, step `.search`. Wires `LocationSearchViewModel` (owned by `RegistrationIntroViewModel`)
/// to the pure layout `LocationSearchContent` and presents the photo sheet `GardenPhotoPickerView`.
/// It lives inside `RegistrationIntroView`'s sheet, so its previews show it through that sheet.
struct LocationSearchView: View {
    @State private var viewModel: RegistrationIntroViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    init(viewModel: RegistrationIntroViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        @Bindable var searchViewModel = viewModel.searchViewModel
        LocationSearchContent(
            query: $searchViewModel.query, isSearchFocused: $isSearchFocused,
            results: searchViewModel.results, isSearching: searchViewModel.isSearching,
            isLocating: searchViewModel.isLocating, errorMessage: searchViewModel.errorMessage,
            onSelect: { location in
                isSearchFocused = false
                searchViewModel.selectResult(location)
            },
            onCurrentLocation: {
                isSearchFocused = false
                searchViewModel.requestCurrentLocation()
            },
            onPhoto: {
                isSearchFocused = false
                searchViewModel.cancelPendingWork()
                viewModel.openPhotoPicker()
            },
            onClose: { viewModel.cancel(); dismiss() }
        )
        .task { isSearchFocused = !searchViewModel.query.isEmpty }
        .task(id: searchViewModel.query) { await searchViewModel.search() }
        .task(id: searchViewModel.locationRequestID) { await searchViewModel.locateCurrentIfRequested() }
        .sheet(isPresented: $viewModel.showsPhotoPicker, onDismiss: viewModel.photoPickerDidDismiss) {
            GardenPhotoPickerView(viewModel: viewModel.photoViewModel)
        }
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .onDisappear {
            searchViewModel.cancelPendingWork()
            viewModel.cancel()
        }
    }
}

#if DEBUG
#Preview("Pencarian · Kosong") {
    RegistrationSheetPreview {
        RegistrationIntroView(viewModel: GardenRegistrationPreview.introViewModel(step: .search))
    }
}

#Preview("Pencarian · Ada hasil") {
    RegistrationSheetPreview {
        RegistrationIntroView(viewModel: GardenRegistrationPreview.introViewModel(
            step: .search, query: "smkn gunung kijang", showsResults: true
        ))
    }
}

#Preview("Pencarian · Offline") {
    RegistrationSheetPreview {
        RegistrationIntroView(viewModel: GardenRegistrationPreview.introViewModel(
            step: .search, query: "dumai", locations: .offline
        ))
    }
}
#endif
