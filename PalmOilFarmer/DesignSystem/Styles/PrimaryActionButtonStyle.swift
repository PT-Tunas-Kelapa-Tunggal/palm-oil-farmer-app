import SwiftUI

/// Keep the shared appearance while letting SwiftUI handle interaction and accessibility.
struct PrimaryActionButtonStyle: PrimitiveButtonStyle {
    var isProminent = true

    func makeBody(configuration: Configuration) -> some View {
        if isProminent {
            Button(configuration)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(KropsTheme.buttonBackground)
                .controlSize(.large)
        } else {
            Button(configuration)
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .foregroundStyle(.primary)
                .controlSize(.large)
        }
    }
}

