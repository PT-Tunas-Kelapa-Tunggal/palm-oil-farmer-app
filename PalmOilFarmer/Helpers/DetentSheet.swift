import SwiftUI
import MapKit

/// A sheet that stays open and can be dragged between several sizes, while the view behind it
/// (usually a map) stays usable at the smaller sizes. Use `DynamicSheet` when the sheet has one size.
///
/// ```swift
/// @State private var detent: PresentationDetent = .height(90)
///
/// .sheet(isPresented: .constant(true)) {
///     DetentSheet(detents: [.height(90), .fraction(0.3), .medium], selection: $detent,
///                 backgroundInteractiveUpThrough: .fraction(0.3)) {
///         SheetContent()
///     }
/// }
/// ```
///
/// - `detents`: the heights the sheet can rest at; `selection` must be one of them.
///   `DynamicSheetSize` values work too, through `.detent` (e.g. `DynamicSheetSize.small.detent`).
/// - `selection`: the current height; set it from code to grow or shrink the sheet.
/// - `backgroundInteractiveUpThrough`: the view behind can be touched up to and including this height;
///   above it, it is dimmed and locked. `nil` locks it at every height.
struct DetentSheet<Content: View>: View {
    let detents: Set<PresentationDetent>
    @Binding var selection: PresentationDetent
    var backgroundInteractiveUpThrough: PresentationDetent? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .presentationDetents(detents, selection: $selection)
            .presentationBackgroundInteraction(backgroundInteraction)
            // Dragging the content resizes the sheet first, then scrolls once it is at its largest height.
            .presentationContentInteraction(.resizes)
            .presentationDragIndicator(.visible)
            // Always open: swiping down stops at the smallest height instead of closing.
            .interactiveDismissDisabled()
    }

    private var backgroundInteraction: PresentationBackgroundInteraction {
        guard let limit = backgroundInteractiveUpThrough else { return .disabled }
        return .enabled(upThrough: limit)
    }
}

#if DEBUG
private struct DetentSheetPreview: View {
    private static let collapsed = PresentationDetent.height(90)
    private static let detail = PresentationDetent.fraction(0.3)
    @State private var detent = collapsed

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: .init(latitude: 1.1047, longitude: 104.1214),
            latitudinalMeters: 1000, longitudinalMeters: 1000
        )))
        .sheet(isPresented: .constant(true)) {
            DetentSheet(detents: [Self.collapsed, Self.detail, .medium], selection: $detent,
                        backgroundInteractiveUpThrough: Self.detail) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kondisi Pohon").font(.headline)
                    Text("108 dari 228 pohon perlu diperhatikan")
                        .font(.subheadline)
                        .foregroundStyle(KropsTheme.labelSecondary)
                    if detent != Self.collapsed {
                        Button(detent == .medium ? "Kecilkan" : "Besarkan") {
                            detent = detent == .medium ? Self.detail : .medium
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
}

#Preview("DetentSheet · Peta, 3 ukuran") {
    DetentSheetPreview()
}
#endif
