import SwiftUI

struct RegistrationHeader: View {
    var title = ""
    var closeSymbol = "xmark"
    var trailingSymbol: String? = nil
    var trailingLabel = ""
    var isTrailingEnabled = true
    var onTrailing: (() -> Void)? = nil
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 72)
                .padding(.vertical, 20)
                .accessibilityAddTraits(.isHeader)
            HStack {
                RegistrationIconButton(symbol: closeSymbol,
                                       label: closeSymbol == "xmark" ? "Tutup" : "Kembali",
                                       action: onClose)
                Spacer(minLength: 0)
                if let trailingSymbol, let onTrailing {
                    RegistrationIconButton(symbol: trailingSymbol, label: trailingLabel,
                                           isProminent: trailingSymbol == "checkmark", action: onTrailing)
                        .disabled(!isTrailingEnabled)
                }
            }
            .padding(12)
        }
        .frame(minHeight: 72)
    }
}
