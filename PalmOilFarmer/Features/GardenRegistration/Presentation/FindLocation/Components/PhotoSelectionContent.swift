import SwiftUI
import UIKit

/// Photo preview: the photo, when it was taken, and its GPS position or a no-GPS warning.
struct PhotoSelectionContent: View {
    var location: GardenLocation?
    var image: UIImage? = nil
    var referenceMapImage: String? = nil
    var isLoadingImage = false

    var creationDate: Date? = nil
    var hasNoLocation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Color.clear.frame(height: 400).overlay {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else if isLoadingImage {
                        ProgressView("Memuat foto…")
                    } else {
                        Image(systemName: "photo").font(.system(size: 80)).foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibilityLabel("Foto terpilih")
                VStack(alignment: .leading, spacing: 16) {
                    metadataRow(symbol: "calendar", caption: "Waktu foto diambil",
                                value: creationDate.map {
                                    $0.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "id_ID"))) + ", " + $0.formatted(.dateTime.hour().minute().locale(Locale(identifier: "id_ID")))
                                } ?? "Waktu tidak tersimpan")
                    Divider()
                    if hasNoLocation {
                        HStack(alignment: .center, spacing: 14) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lokasi tidak tersimpan di foto").font(.footnote).foregroundStyle(.secondary)
                                Text("Foto ini tidak bisa dipakai").font(.headline)
                                Text("Layanan Lokasi untuk Kamera belum aktif saat foto diambil. Aktifkan di Pengaturan, lalu ambil foto baru di kebun.")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    } else if let location {
                        metadataRow(symbol: "location.fill", caption: "Lokasi tersimpan di foto",
                                    value: String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude))
                    } else {
                        ProgressView("Mencari alamat foto…")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RegistrationStyle.surface, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func metadataRow(symbol: String, caption: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).foregroundStyle(RegistrationStyle.actionTint)
            VStack(alignment: .leading, spacing: 4) {
                Text(caption).font(.footnote).foregroundStyle(.secondary)
                Text(value).font(.headline)
            }
        }
    }
}

#if DEBUG
#Preview("Foto terpilih · Ada lokasi") {
    PhotoSelectionContent(location: GardenRegistrationPreview.photoLocation,
                          image: UIImage(named: "RegistrationPhotoReference"),
                          creationDate: Date(timeIntervalSince1970: 1_793_582_040))
        .background(RegistrationStyle.background)
}

#Preview("Foto terpilih · Tanpa lokasi") {
    PhotoSelectionContent(image: UIImage(named: "RegistrationPhotoReference"),
                          creationDate: Date(timeIntervalSince1970: 1_793_582_040), hasNoLocation: true)
        .background(RegistrationStyle.background)
}

#Preview("Foto terpilih · Memuat") {
    PhotoSelectionContent(isLoadingImage: true)
        .background(RegistrationStyle.background)
}
#endif
