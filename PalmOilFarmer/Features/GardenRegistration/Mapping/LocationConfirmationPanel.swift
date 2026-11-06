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
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left").font(.title2)
                            Text(location.name).font(.title2.bold())
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Kembali ke pencarian lokasi")
                    VStack(alignment: .leading, spacing: 8) {
                        Text(location.subtitle).font(.body)
                        Text(coordinateText).font(.body).foregroundStyle(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                }
                RegistrationPrimaryButton(title: location.source == .photo ? "Gunakan Lokasi Ini" : "Lanjut",
                                         action: onContinue)
                if let onSaveDraft {
                    Button("Simpan lokasi dulu", action: onSaveDraft)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
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
