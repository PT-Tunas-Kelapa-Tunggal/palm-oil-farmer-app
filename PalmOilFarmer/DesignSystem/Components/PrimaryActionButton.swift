import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    var systemImage: String? = nil
    var imagePlacement: ImagePlacement = .leading
    let action: () -> Void

    enum ImagePlacement {
        case leading, trailing
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage, imagePlacement == .leading {
                    Image(systemName: systemImage)
                        .fontWeight(.semibold)
                }
                Text(title)
                    .fontWeight(.semibold)
                if let systemImage, imagePlacement == .trailing {
                    Image(systemName: systemImage)
                        .fontWeight(.semibold)
                }
            }
            .font(.body)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .contentShape(Capsule())
        }
        .buttonStyle(PrimaryActionButtonStyle())
    }
}

#if DEBUG
#Preview("Primary Button States", traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        PrimaryActionButton(title: "Lanjut", action: {})
        PrimaryActionButton(title: "Daftarkan Kebun", systemImage: "plus", action: {})
        PrimaryActionButton(title: "Simpan", action: {})
            .disabled(true)
    }
    .padding(24)
    .frame(width: 402)
    .background(KropsTheme.background)
}

#Preview("Primary Button Style", traits: .sizeThatFitsLayout) {
    Button("Konfirmasi", systemImage: "checkmark", action: {})
        .frame(maxWidth: .infinity, minHeight: 52)
        .buttonStyle(PrimaryActionButtonStyle())
        .padding(24)
        .frame(width: 402)
}
#endif
