import SwiftUI

/// A blur that strengthens toward the bottom edge, placed behind bottom actions so scrolling
/// content softens under them instead of being cut off by a solid band.
struct BottomBlurFade: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask {
                LinearGradient(stops: [.init(color: .clear, location: 0),
                                       .init(color: .black.opacity(0.85), location: 0.45),
                                       .init(color: .black, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
    }
}
