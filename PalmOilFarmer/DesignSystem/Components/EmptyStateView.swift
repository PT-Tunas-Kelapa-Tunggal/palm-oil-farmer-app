import SwiftUI

struct EmptyStateView<Illustration: View>: View {
    let title: String
    let message: String
    var messageFont: Font = .title2
    @ViewBuilder let illustration: () -> Illustration

    var body: some View {
        VStack(spacing: KropsTheme.Spacing.section) {
            illustration()
                .foregroundStyle(KropsTheme.secondaryText)
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text(message)
                    .font(messageFont)
                    .foregroundStyle(KropsTheme.secondaryText)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, KropsTheme.Spacing.content)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Empty State", traits: .sizeThatFitsLayout) {
    EmptyStateView(
        title: "Belum ada kebun terdaftar",
        message: "Gambar batas kebun di peta untuk mulai memantau kondisi dan hasil panen."
    ) {
        SeedlingIcon()
    }
    .frame(width: 402)
    .padding(.vertical, 32)
    .background(KropsTheme.background)
}
#endif
