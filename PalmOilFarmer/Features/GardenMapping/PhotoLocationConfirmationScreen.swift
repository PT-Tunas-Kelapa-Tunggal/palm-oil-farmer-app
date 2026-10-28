import SwiftUI
import MapKit

struct PhotoLocationConfirmationScreen: View {
    let location: GardenLocation
    let onConfirm: () -> Void
    let onSearchAgain: () -> Void

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: location.coordinate.mapCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))) {
            Marker("Lokasi dari foto", coordinate: location.coordinate.mapCoordinate)
                .tint(.gray)
        }
        .mapStyle(.imagery)
        .mapControls {}
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Lokasi Ditemukan dari Foto").font(.title2.bold())
                Text("Pastikan titik yang ditampilkan di peta adalah lokasi kebun Anda.")
                    .font(.subheadline)
                PrimaryActionButton(title: "Ya, Ini kebun saya", action: onConfirm)
                Button("Cari Lagi", action: onSearchAgain)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background { SheetGlassBackground() }
            .padding(.horizontal, 8)
        }
    }
}

#if DEBUG
#Preview("Konfirmasi lokasi foto") {
    PhotoLocationConfirmationScreen(location: GardenPreviewData.location, onConfirm: {}, onSearchAgain: {})
}
#endif
