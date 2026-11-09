import SwiftUI

/// Shared map panel surface, spacing, and scrolling for content that exceeds the available height.
struct MapBottomPanel<Content: View>: View {
    @State private var contentHeight: CGFloat = 1
    var insets = EdgeInsets(top: 28, leading: 18, bottom: 32, trailing: 16)
    @ViewBuilder let content: () -> Content

    private var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: RegistrationStyle.panelTopRadius,
            bottomLeadingRadius: RegistrationStyle.panelBottomRadius,
            bottomTrailingRadius: RegistrationStyle.panelBottomRadius,
            topTrailingRadius: RegistrationStyle.panelTopRadius
        )
    }

    var body: some View {
        ScrollView {
            content()
                .fixedSize(horizontal: false, vertical: true)
                .padding(insets)
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { height in
                    contentHeight = height
                }
        }
        .containerRelativeFrame(.vertical, alignment: .bottom) { availableHeight, _ in
            // Reserve room for the map and its header, including in landscape and split view.
            min(contentHeight, max(1, availableHeight * 0.45))
        }
        .scrollBounceBehavior(.basedOnSize)
        .overlay(alignment: .top) {
            Capsule().fill(.white.opacity(0.4)).frame(width: 36, height: 5).padding(.top, 6)
                .accessibilityHidden(true)
        }
        .glassEffect(.regular, in: panelShape)
        .clipShape(panelShape)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .environment(\.colorScheme, .dark)
    }
}
