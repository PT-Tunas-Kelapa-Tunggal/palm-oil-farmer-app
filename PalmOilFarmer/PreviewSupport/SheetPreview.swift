#if DEBUG
import SwiftUI

/// Canvas helper for every feature: shows `content` the way the app presents it, as a sheet over a backdrop.
/// Use it in `#Preview` for any view whose body is a `DynamicSheet`
/// (sheet presentation modifiers only take effect inside a real sheet).
struct SheetPreview<Content: View>: View {
    /// Asset name drawn behind the sheet, e.g. a satellite map. `nil` uses a plain gray backdrop.
    var backdrop: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        Color(uiColor: .systemGray5)
            .overlay {
                if let backdrop {
                    Image(backdrop).resizable().scaledToFill()
                }
            }
            .clipped()
            .ignoresSafeArea()
            .sheet(isPresented: .constant(true)) { content() }
    }
}
#endif
