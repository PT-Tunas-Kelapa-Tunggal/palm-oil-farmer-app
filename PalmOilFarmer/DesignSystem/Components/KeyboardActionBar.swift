import SwiftUI

/// Berikutnya / Selesai buttons floating just above the keyboard. Place it in a bottom safe-area inset
/// while a field is focused, so the content above also scrolls clear of it.
struct KeyboardActionBar: View {
    var onNext: (() -> Void)?
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            if let onNext {
                Button(action: onNext) {
                    Label("Berikutnya", systemImage: "chevron.down")
                }
                .buttonStyle(.glass)
                .foregroundStyle(.primary)
            }
            Button(action: onDone) {
                Text("Selesai").fontWeight(.semibold)
            }
            .buttonStyle(.glassProminent)
            .tint(KropsTheme.buttonBackground)
        }
        // Small controls keep attention on the field being filled.
        .font(.subheadline)
        .buttonBorderShape(.capsule)
        .controlSize(.small)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        // Fades the content scrolling underneath, like the system scroll edge effect.
        .background { BottomBlurFade() }
    }
}
