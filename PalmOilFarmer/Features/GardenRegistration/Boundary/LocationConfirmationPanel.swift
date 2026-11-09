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
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(location.name).font(.title2.bold())
                    Text(location.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    Text(coordinateText).font(.footnote).foregroundStyle(.tertiary)
                }
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
#Preview("Konfirmasi lokasi") {
    Color.gray
        .overlay(alignment: .bottom) {
            LocationConfirmationPanel(location: GardenPreviewData.location, onBack: {}, onContinue: {})
        }
        .ignoresSafeArea(.container, edges: .bottom)
}
#Preview("Konfirmasi lokasi · Teks besar") {
    Color.gray
        .overlay(alignment: .bottom) {
            LocationConfirmationPanel(location: GardenPreviewData.location, onBack: {}, onContinue: {})
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
