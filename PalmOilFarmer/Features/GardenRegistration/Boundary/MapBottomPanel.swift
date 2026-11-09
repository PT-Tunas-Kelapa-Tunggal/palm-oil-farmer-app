import SwiftUI

/// Content layout shared by the native map sheets. Presentation belongs to the map flow.
struct MapBottomPanel<Content: View>: View {
    var insets = EdgeInsets(top: 24, leading: 18, bottom: 24, trailing: 18)
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content()
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(insets)
                    .frame(minHeight: geometry.size.height, alignment: .center)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
