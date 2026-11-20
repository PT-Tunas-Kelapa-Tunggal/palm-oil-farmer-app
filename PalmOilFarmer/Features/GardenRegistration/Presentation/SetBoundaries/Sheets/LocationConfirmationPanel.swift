import SwiftUI

/// Asks "is this the right place?" before mapping starts.
/// Layout follows Sketch "Feature / GardenRegistration / FindLocation / Confirm Location".
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

    /// Coordinates, plus when the photo was taken for a photo location ("Foto 2 Nov 2026").
    private var detailText: String {
        guard location.source == .photo, let photoDate = location.photoDate else { return coordinateText }
        let date = photoDate.formatted(.dateTime.day().month(.abbreviated).year()
            .locale(Locale(identifier: "id_ID")))
        return "\(coordinateText)  ·  Foto \(date)"
    }

    var body: some View {
        VStack(spacing: KropsTheme.Spacing.field) {
            GeometryReader { geometry in
                ScrollView {
                    locationInfo
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geometry.size.height, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            RegistrationPrimaryButton(
                title: location.source == .search ? "Patokan Sudah Benar" : "Gunakan Lokasi Ini",
                action: onContinue
            )
        }
        .padding(.horizontal, KropsTheme.Spacing.screen)
        .padding(.top, KropsTheme.Spacing.screen)
        .padding(.bottom, KropsTheme.Spacing.field)
    }

    /// Place name, address and coordinates. Only this part scrolls when it is long,
    /// so the button stays at the bottom, level with the drawing guide's button.
    private var locationInfo: some View {
        VStack(spacing: 2) {
            Text(location.name)
                .font(.title2.bold())
                .foregroundStyle(KropsTheme.labelPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(location.subtitle)
                .font(.subheadline)
                .foregroundStyle(KropsTheme.labelSecondary)
            Text(detailText)
                .font(.footnote)
                .foregroundStyle(KropsTheme.labelTertiary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 8)
    }
}

#if DEBUG
private struct LocationConfirmationPanelPreview: View {
    let location: GardenLocation
    let backdrop: String

    var body: some View {
        SheetPreview(backdrop: backdrop) {
            DynamicSheet(animation: .bouncy, size: .xsmall) {
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
