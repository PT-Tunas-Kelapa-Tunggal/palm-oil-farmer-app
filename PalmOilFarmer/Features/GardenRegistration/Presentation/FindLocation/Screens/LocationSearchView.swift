import SwiftUI

/// Content of the "Cari Lokasi" sheet, step `.search`. Wires `LocationSearchViewModel`
/// to the pure layout `LocationSearchContent` and presents the photo sheet `GardenPhotoPickerView`.
/// It lives inside `RegistrationIntroView`'s sheet, so its previews show it through that sheet.
struct LocationSearchView: View {
    @State private var flow: GardenRegistrationFlow
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    init(flow: GardenRegistrationFlow) {
        _flow = State(initialValue: flow)
    }

    var body: some View {
        @Bindable var model = flow.searchViewModel
        @Bindable var coordinator = flow.coordinator
        LocationSearchContent(
            query: $model.query, isSearchFocused: $isSearchFocused,
            results: model.results, isSearching: model.isSearching,
            isLocating: model.isLocating, errorMessage: model.errorMessage,
            onSelect: { location in
                isSearchFocused = false
                model.selectResult(location)
            },
            onCurrentLocation: {
                isSearchFocused = false
                model.requestCurrentLocation()
            },
            onPhoto: {
                isSearchFocused = false
                model.cancelPendingWork()
                coordinator.openPhotoPicker()
            },
            onClose: { coordinator.cancel(); dismiss() }
        )
        .task { isSearchFocused = !model.query.isEmpty }
        .task(id: model.query) { await model.search() }
        .task(id: model.locationRequestID) { await model.locateCurrentIfRequested() }
        .sheet(isPresented: $coordinator.showsPhotoPicker, onDismiss: coordinator.photoPickerDidDismiss) {
            GardenPhotoPickerView(viewModel: flow.photoViewModel)
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .onDisappear {
            model.cancelPendingWork()
            coordinator.cancel()
        }
    }
}

#if DEBUG
#Preview("Pencarian · Kosong") {
    RegistrationSheetPreview {
        RegistrationIntroView(flow: GardenRegistrationPreview.registrationFlow(step: .search))
    }
}

#Preview("Pencarian · Ada hasil") {
    RegistrationSheetPreview {
        RegistrationIntroView(flow: GardenRegistrationPreview.registrationFlow(
            step: .search, query: "smkn gunung kijang", showsResults: true
        ))
    }
}

#Preview("Pencarian · Offline") {
    RegistrationSheetPreview {
        RegistrationIntroView(flow: GardenRegistrationPreview.registrationFlow(
            step: .search, query: "dumai", locations: .offline
        ))
    }
}
#endif
