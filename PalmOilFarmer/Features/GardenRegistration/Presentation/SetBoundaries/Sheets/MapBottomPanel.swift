import SwiftUI

/// Content layout shared by the map's bottom sheets.
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

#if DEBUG
#Preview("Panel bawah peta") {
    SheetPreview(backdrop: "RegistrationSearchSatellite") {
        DynamicSheet(animation: .bouncy, size: .small) {
            MapBottomPanel {
                Text("Isi panel apa pun").font(.title3.bold())
            }
        }
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.hidden)
    }
}
#endif
