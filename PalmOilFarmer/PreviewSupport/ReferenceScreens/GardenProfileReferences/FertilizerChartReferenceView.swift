#if DEBUG
import SwiftUI

struct FertilizerChartReferenceView: View {
    let values: [Double]
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Riwayat pupuk").font(.title3.weight(.semibold))
            // Compute the scale once per render rather than once for every bar.
            let maximum = max(values.max() ?? 1, 1)
            GeometryReader { geometry in
                HStack(alignment: .bottom, spacing: 36) {
                    ForEach(values.indices, id: \.self) { index in
                        Rectangle()
                            .fill(Color(red: 0.84, green: 0.86, blue: 1))
                            .frame(height: max(0, values[index]) / maximum * geometry.size.height)
                    }
                }
                .padding(.horizontal, 18)
                .overlay(alignment: .top) {
                    Line().stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                        .frame(height: 1).offset(y: 45)
                }
                .overlay(alignment: .bottom) { Divider() }
            }
            .frame(height: 154)
            Button(action: onContinue) {
                HStack {
                    Text("Lengkapi riwayat panen")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(KropsTheme.cardFill, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: rect.width, y: 0))
            }
        }
    }
}


#Preview("Referensi · Grafik pemupukan", traits: .sizeThatFitsLayout) {
    FertilizerChartReferenceView(values: [1, 3, 1.5, 0.5], onContinue: {})
        .padding().frame(width: 402)
}
#endif
