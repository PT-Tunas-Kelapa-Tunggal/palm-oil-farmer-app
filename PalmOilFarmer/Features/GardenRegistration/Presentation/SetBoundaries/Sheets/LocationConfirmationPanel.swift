import SwiftUI

/// Asks "is this the right place?" before mapping starts.
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
private struct LocationConfirmationPanelPreview: View {
    let location: GardenLocation
    let backdrop: String

    var body: some View {
        RegistrationSheetPreview(backdrop: backdrop) {
            DynamicSheet(animation: .bouncy, size: .small) {
                LocationConfirmationPanel(location: location, onBack: {}, onContinue: {})
            }
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.hidden)
        }
    }
}

#Preview("Konfirmasi lokasi · Pencarian") {
    LocationConfirmationPanelPreview(location: GardenRegistrationPreview.searchLocation,
                                     backdrop: "RegistrationSearchSatellite")
}

#Preview("Konfirmasi lokasi · GPS") {
    LocationConfirmationPanelPreview(location: GardenRegistrationPreview.currentLocation,
                                     backdrop: "RegistrationCurrentSatellite")
}

#Preview("Konfirmasi lokasi · Foto") {
    LocationConfirmationPanelPreview(location: GardenRegistrationPreview.photoLocation,
                                     backdrop: "RegistrationPhotoSatellite")
}

#Preview("Konfirmasi lokasi · Teks besar") {
    LocationConfirmationPanelPreview(location: GardenRegistrationPreview.photoLocation,
                                     backdrop: "RegistrationPhotoSatellite")
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
