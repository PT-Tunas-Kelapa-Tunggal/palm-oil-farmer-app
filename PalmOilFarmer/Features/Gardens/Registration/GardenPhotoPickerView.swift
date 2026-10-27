import SwiftUI
import PhotosUI

struct GardenPhotoPickerView: View {
    var isReadingPhoto = false
    var onOpen: () -> Void = {}
    let onSelect: (PhotosPickerItem) -> Void

    @State private var showsPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Button {
            onOpen()
            selectedPhoto = nil
            showsPhotoPicker = true
        } label: {
            VStack(spacing: 8) {
                if isReadingPhoto {
                    ProgressView("Memeriksa foto…")
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                    Text("Temukan Lokasi Kebun dari Foto")
                        .font(.subheadline.weight(.semibold))
                    Text("Pilih foto asli yang diambil di kebun dengan kamera iPhone dan lokasi kamera aktif. Foto dari WhatsApp atau Instagram mungkin tidak menyimpan lokasi.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .disabled(isReadingPhoto)
        // Let iOS present the picker and manage its own header, dismissal, and safe areas.
        .photosPicker(isPresented: $showsPhotoPicker, selection: $selectedPhoto,
                      matching: .all(of: [.images, .not(.screenshots)]),
                      preferredItemEncoding: .current)
        .onChange(of: selectedPhoto) { _, photo in
            guard let photo else { return }
            onSelect(photo)
        }
    }
}

#Preview("04 · Pilih Foto Galeri") {
    GardenPhotoPickerView(onSelect: { _ in })
        .padding()
}
