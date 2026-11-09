import SwiftUI

struct LocationConfirmationPanel: View {
    let location: GardenLocation
    var onSaveDraft: (() -> Void)? = nil
    let onBack: () -> Void
    let onContinue: () -> Void

    private var coordinateText: String {
        let format = FloatingPointFormatStyle<Double>.number
            .precision(.fractionLength(6))
            .locale(Locale(identifier: "en_US_POSIX"))
        let latitude = location.coordinate.latitude.formatted(format)
        let longitude = location.coordinate.longitude.formatted(format)
        return "\(latitude), \(longitude)"
    }

    var body: some View {
        MapBottomPanel {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(location.name)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(location.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    Text(coordinateText).font(.footnote).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                RegistrationPrimaryButton(
                    title: location.source == .search ? "Patokan Sudah Benar" : "Gunakan Lokasi Ini",
                    action: onContinue
                )
            }
        }
    }
}

#if DEBUG
private let confirmationPreviewLocation = GardenLocation(
    name: "Malang Rapat",
    subtitle: "Kecamatan Gunung Kijang, Kabupaten Bintan, Kepulauan Riau",
    coordinate: GardenCoordinate(latitude: 1.104950, longitude: 104.121010),
    source: .photo
)

#Preview("Konfirmasi lokasi") {
    Color.gray
        .sheet(isPresented: .constant(true)) {
            DynamicSheet(animation: .bouncy, size: .small) {
                LocationConfirmationPanel(location: confirmationPreviewLocation, onBack: {}, onContinue: {})
            }
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.hidden)
        }
        .ignoresSafeArea(.container, edges: .bottom)
}
#Preview("Konfirmasi lokasi · Teks besar") {
    Color.gray
        .sheet(isPresented: .constant(true)) {
            DynamicSheet(animation: .bouncy, size: .small) {
                LocationConfirmationPanel(location: confirmationPreviewLocation, onBack: {}, onContinue: {})
            }
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.hidden)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
