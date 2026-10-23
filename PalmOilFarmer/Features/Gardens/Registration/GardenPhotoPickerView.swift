import SwiftUI
import PhotosUI

struct GardenPhotoPickerView: View {
    let onSelect: (PhotosPickerItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Album Kamera", onClose: { dismiss() })
            PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .current) {
                EmptyView()
            }
            .photosPickerStyle(.inline)
            .photosPickerAccessoryVisibility(.hidden, edges: .all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .presentationDetents([.large])
        .onChange(of: selectedPhoto) { _, photo in
            guard let photo else { return }
            onSelect(photo)
            dismiss()
        }
    }
}

#Preview("04 · Pilih Foto Galeri") {
    GardenPhotoPickerView(onSelect: { _ in })
}
