import SwiftUI
import UIKit

/// Sizes a sheet to its content so it never leaves an empty band below the last control.
/// A height detent is placed above the screen's bottom safe area, so the content extends into that
/// area and the detent is shortened by it; the content's own bottom padding then sets the gap, so
/// match it to the side margins. Content taller than the screen falls back to the tallest detent and scrolls.
struct FittedSheetHeight: ViewModifier {
    @State private var contentHeight: CGFloat?

    private var bottomInset: CGFloat {
        let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        return scene?.keyWindow?.safeAreaInsets.bottom ?? 0
    }

    func body(content: Content) -> some View {
        ScrollView {
            content
        }
        .scrollBounceBehavior(.basedOnSize)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentSize.height.rounded(.up)
        } action: { _, newHeight in
            contentHeight = newHeight
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .presentationDetents(contentHeight.map { [.height(max($0 - bottomInset, 120))] } ?? [.medium])
    }
}

extension View {
    func fittedSheetHeight() -> some View {
        modifier(FittedSheetHeight())
    }
}
