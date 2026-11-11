import SwiftUI
import UIKit

/// One square cell in the `GardenPhotoPickerView` gallery; streams its thumbnail from the view model.
struct CameraPhotoThumbnail: View {
    let photoID: String
    let viewModel: GardenPhotoPickerViewModel
    @State private var image: UIImage?

    var body: some View {
        Color(uiColor: .systemBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo.fill").foregroundStyle(.tertiary)
                }
            }
            .clipped()
            .task(id: photoID) {
                for await data in viewModel.thumbnails(for: photoID) {
                    guard !Task.isCancelled else { return }
                    if let result = UIImage(data: data) { image = result }
                }
            }
    }
}

#if DEBUG
#Preview("Thumbnail galeri", traits: .sizeThatFitsLayout) {
    let viewModel = GardenRegistrationPreview.photoPickerViewModel()
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4), spacing: 2) {
        ForEach(0..<8) { index in
            CameraPhotoThumbnail(photoID: "dummy-photo-\(index)", viewModel: viewModel)
        }
    }
    .frame(width: 402)
}
#endif
