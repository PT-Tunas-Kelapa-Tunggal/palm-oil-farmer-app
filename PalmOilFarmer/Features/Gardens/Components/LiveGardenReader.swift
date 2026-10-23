import SwiftUI

/// A pushed destination can keep showing the value its parent had when it was pushed.
/// Screens that change a garden while pushed read the latest copy from the store instead.
struct LiveGardenReader<Content: View>: View {
    let garden: Garden
    @ViewBuilder let content: (Garden) -> Content
    @Environment(GardenStore.self) private var store: GardenStore?

    var body: some View {
        content(store?.gardens.first { $0.id == garden.id } ?? garden)
    }
}
