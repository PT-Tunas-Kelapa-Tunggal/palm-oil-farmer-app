import SwiftUI

struct EmptyStateView<Illustration: View>: View {
    let title: String
    let message: String
    @ViewBuilder let illustration: () -> Illustration

    var body: some View {
        VStack(spacing: KropsTheme.Spacing.section) {
            illustration()
                .foregroundStyle(KropsTheme.secondaryText)
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(KropsTheme.primaryText)

                Text(message)
                    .font(.title2)
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
        title: "Belum ada data",
        message: "Tambahkan data pertama untuk memulai."
    ) {
        Image(systemName: "tray").font(.system(size: 64))
    }
    .frame(width: 402)
    .padding(.vertical, 32)
    .background(KropsTheme.background)
}
#endif
