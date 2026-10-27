import SwiftUI

/// Keep the shared appearance while letting SwiftUI handle interaction and accessibility.
struct PrimaryActionButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .tint(KropsTheme.buttonBackground)
            .controlSize(.large)
    }
}
