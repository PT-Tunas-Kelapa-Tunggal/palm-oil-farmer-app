import SwiftUI

/// Placeholder for the "dose per tree on map" screen.
struct FertilizerExampleScreen: View {
    var body: some View {
        Text("example screen")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        FertilizerExampleScreen()
    }
}
#endif
