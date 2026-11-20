import SwiftUI

enum DynamicSheetSize: String, CaseIterable {
    case xsmall = "xSmall"
    case small = "Small"
    case medium = "Medium"
    case halfscreen = "Half"
    case large = "Large"

    var detent: PresentationDetent {
        switch self {
        case .xsmall: .height(180)
        case .small: .height(210)
        case .medium: .height(330)
        case .halfscreen: .height(550)
        case .large: .large
        }
    }
}

struct DynamicSheet<Content: View>: View {
    var animation: Animation
    var size: DynamicSheetSize = .small
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .presentationDetents([size.detent])
            .interactiveDismissDisabled()
            .animation(reduceMotion ? nil : animation, value: size)
    }
}

#if DEBUG
private struct DynamicSheetPreview: View {
    @State private var size: DynamicSheetSize = .medium
    @State private var isPresented = true

    var body: some View {
        Color.gray.opacity(0.15)
            .ignoresSafeArea()
            .sheet(isPresented: $isPresented) {
                DynamicSheet(animation: .bouncy, size: size) {
                    VStack(spacing: 16) {
                        Text("Hello from Dynamic sheet")
                            .font(.headline)

                        Picker("Ukuran sheet", selection: $size) {
                            ForEach(DynamicSheetSize.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 30)
                }
                .presentationDragIndicator(.hidden)
            }
    }
}

#Preview("DynamicSheet") {
    DynamicSheetPreview()
}
#endif
