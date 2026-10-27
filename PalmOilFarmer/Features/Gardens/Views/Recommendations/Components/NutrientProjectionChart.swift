import SwiftUI

struct NutrientProjectionChart: View {
    let values: [NutrientProjection]
    @ScaledMetric(relativeTo: .caption) private var statusHeight = 32
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var references: [NutrientReference] = []
    var onReference: (NutrientReference) -> Void = { _ in }

    private var maximum: Double {
        max(1, values.map { max($0.current, $0.target, $0.requirement) }.max() ?? 1)
    }

    var body: some View {
        VStack(spacing: 16) {
            legend
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(values) { value in
                    VStack(spacing: 6) {
                        HStack(alignment: .bottom, spacing: 3) {
                            UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                                .fill(.background)
                                .overlay {
                                    UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                                        .stroke(.secondary, lineWidth: 1)
                                }
                                .frame(height: height(value.current))
                            UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                                .fill(Color(white: 0.34))
                                .frame(height: height(value.target))
                        }
                        .frame(height: 125, alignment: .bottom)
                        .overlay {
                            GeometryReader { geometry in
                                Path { path in
                                    let y = 125 - height(value.requirement)
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                }
                                .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            }
                        }
                        .overlay(alignment: .bottom) { Divider() }
                        if let reference = references.first(where: { $0.id == value.name }) {
                            Button(value.name) { onReference(reference) }
                                .font(.subheadline.bold())
                                .buttonStyle(.plain)
                                .accessibilityHint("Lihat referensi pupuk")
                        } else {
                            Text(value.name).font(.subheadline.bold())
                        }
                        Text(value.status ?? "")
                            .font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: statusHeight, alignment: .top)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("\(value.name), saat ini \(value.current), setelah pemupukan \(value.target), kebutuhan \(value.requirement)")
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var legend: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Label {
                Text("Saat ini")
            } icon: { Rectangle().stroke(.secondary).frame(width: 9, height: 9) }
            Label {
                Text("Setelah pemupukan")
            } icon: { Rectangle().fill(Color(white: 0.34)).frame(width: 9, height: 9) }
            Text("┄ Kebutuhan")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func height(_ value: Double) -> CGFloat {
        guard value.isFinite else { return 0 }
        return 125 * max(0, min(value / maximum, 1))
    }
}
