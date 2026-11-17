import SwiftUI

struct RegistrationPrimaryButton: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage, !dynamicTypeSize.isAccessibilitySize { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(KropsTheme.labelInversePrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 20)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(KropsTheme.surfaceInverse)
        .controlSize(.large)
    }
}

#if DEBUG
#Preview("Tombol utama", traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        RegistrationPrimaryButton(title: "Cari Lokasi Kebun") {}
        RegistrationPrimaryButton(title: "Simpan Kebun", systemImage: "checkmark") {}
        RegistrationPrimaryButton(title: "Simpan Batas Kebun") {}
            .disabled(true)
    }
    .padding(24)
    .frame(width: 402)
    .background(KropsTheme.surfaceBackground)
}
#endif
