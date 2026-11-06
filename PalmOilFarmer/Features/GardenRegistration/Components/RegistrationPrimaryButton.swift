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
            .foregroundStyle(RegistrationStyle.onAction)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 20)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(RegistrationStyle.actionTint)
        .controlSize(.large)
    }
}
