import SwiftUI

/// Pins a bottom action to the screen edge so the keyboard covers it instead of pushing it up.
/// The content above keeps its own keyboard avoidance and gets matching bottom room to scroll past the action.
struct BottomActionBar<Action: View>: ViewModifier {
    @ViewBuilder let action: () -> Action
    @State private var actionHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, actionHeight)
            .overlay {
                action()
                    // Content scrolling underneath fades out rather than showing through.
                    .background {
                        LinearGradient(stops: [.init(color: Color(uiColor: .systemBackground).opacity(0), location: 0),
                                               .init(color: Color(uiColor: .systemBackground), location: 0.3)],
                                       startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea(edges: .bottom)
                            .allowsHitTesting(false)
                    }
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
