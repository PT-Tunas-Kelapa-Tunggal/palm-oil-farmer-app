import SwiftUI

/// Reference-preview surface only. Real sheets use the system presentation background.
struct SheetGlassBackground: View {
    var body: some View {
        Color.clear
            .glassEffect(
                .regular,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 34, bottomLeadingRadius: 54,
                    bottomTrailingRadius: 54, topTrailingRadius: 34
                )
            )
    }
}

#Preview("Regular Large · Light and Dark") {
    ZStack {
        Image("CodedProfileMap").resizable().scaledToFill()
        VStack {
            Text("Regular · Large").font(.title2.bold())
            Text("Konten di belakang sheet tetap terlihat melalui Liquid Glass.")
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(width: 340, height: 240)
        .background { SheetGlassBackground() }
    }
    .frame(width: 402, height: 420)
    .clipped()
}
