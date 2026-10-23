import SwiftUI
import UIKit

/// Pins a bottom action to the screen edge so the keyboard covers it instead of pushing it up.
/// The content above keeps its own keyboard avoidance and gets matching bottom room to scroll past the action.
struct BottomActionBar<Action: View>: ViewModifier {
    @ViewBuilder let action: () -> Action
    @State private var actionHeight: CGFloat = 0
    @State private var isKeyboardVisible = false

    func body(content: Content) -> some View {
        content
            // While the keyboard is up it covers the action, so the content needs no room for it.
            .safeAreaPadding(.bottom, isKeyboardVisible ? 0 : actionHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
            .overlay {
                action()
                    // Content scrolling underneath fades out rather than showing through.
                    .background { BottomBlurFade() }
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { actionHeight = $0 }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
    }
}

extension View {
    func bottomActionBar<Action: View>(@ViewBuilder _ action: @escaping () -> Action) -> some View {
        modifier(BottomActionBar(action: action))
    }
}
