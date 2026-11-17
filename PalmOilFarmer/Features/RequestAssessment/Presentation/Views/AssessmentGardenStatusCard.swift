import SwiftUI

/// Shares the status card layout between the in-review and download states.
struct AssessmentGardenStatusCard<Content: View, Actions: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: () -> Content
    @ViewBuilder let actions: () -> Actions

    private var dark: Bool { colorScheme == .dark }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: dark ? 20 : 30)
        VStack(spacing: dark ? 12 : 0) {
            VStack(spacing: 12, content: content)
                .padding(.top, dark ? 0 : 32)
                .padding(.bottom, dark ? 0 : 16)
                .padding(.horizontal, dark ? 0 : 16)

            actions()
                .padding(dark ? 0 : 16)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, dark ? 20 : 0)
        .padding(.top, dark ? 24 : 0)
        .padding(.bottom, dark ? 20 : 0)
        .frame(maxWidth: .infinity)
        .foregroundStyle(KropsTheme.labelPrimary)
        .background {
            KropsTheme.surfaceCard
                .overlay(alignment: .top) {
                    if dark {
                        LinearGradient(colors: [.white.opacity(0.08), .clear],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: 130)
                    }
                }
                .clipShape(shape)
        }
    }
}
