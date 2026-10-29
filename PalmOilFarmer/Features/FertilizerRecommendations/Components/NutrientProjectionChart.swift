import SwiftUI

struct NutrientProjectionChart: View {
    let values: [NutrientProjection]
    @ScaledMetric(relativeTo: .caption) private var statusHeight = 52
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var references: [NutrientReference] = []
    var currentLabel = "Saat ini"
    var targetLabel = "Setelah pemupukan"
    var requirementLabel = "Kebutuhan"
    var onReference: (NutrientReference) -> Void = { _ in }

    private let plotHeight: CGFloat = 212
    private let axisWidth: CGFloat = 48

    private var axisMaximum: Double {
        let largest = values.map { max($0.current, $0.target, $0.requirement) }.max() ?? 0
        return max(2, ceil(largest * 2) / 2)
    }

    private var axisTicks: [Double] {
        Array(stride(from: axisMaximum, through: 0, by: -0.5))
    }

    var body: some View {
        VStack(spacing: 12) {
            legend
            HStack(alignment: .top, spacing: 6) {
                axisLabels
                    .frame(width: axisWidth, height: plotHeight)
                VStack(spacing: 8) {
                    ZStack(alignment: .bottom) {
                        grid
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(values) { value in
                                HStack(alignment: .bottom, spacing: 5) {
                                    if value.currentAvailable {
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(currentColor)
                                            .frame(width: barWidth, height: height(value.current))
                                    } else {
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(.clear)
                                            .frame(width: barWidth, height: 1)
                                    }
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(targetColor)
                                        .frame(width: barWidth, height: height(value.target))
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .frame(height: plotHeight)
                    .overlay {
                        if let requirement = values.first?.requirement {
                            GeometryReader { geometry in
                                Path { path in
                                    let y = plotHeight - height(requirement)
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                }
                                .stroke(.secondary, style: StrokeStyle(lineWidth: 1.4, dash: [4, 5]))
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 8) {
                        ForEach(values) { value in
                            VStack(spacing: 4) {
                                if let reference = references.first(where: { $0.id == value.name }) {
                                    Button(value.name) { onReference(reference) }
                                        .font(.title3.bold())
                                        .buttonStyle(.plain)
                                        .accessibilityHint("Lihat referensi pupuk")
                                } else {
                                    Text(value.name).font(.title3.bold())
                                }
                                Text(statusTitle(value.status))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(statusColor(value.status))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .frame(maxWidth: .infinity, minHeight: statusHeight, alignment: .top)
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("\(value.name), \(value.currentAvailable ? "\(currentLabel) \(value.current.formatted(.percent.precision(.fractionLength(0))))" : "\(currentLabel) belum tersedia"), \(targetLabel) \(value.target.formatted(.percent.precision(.fractionLength(0)))), \(requirementLabel) \(value.requirement.formatted(.percent.precision(.fractionLength(0))))")
                        }
                    }
                }
            }
        }
    }

    private var axisLabels: some View {
        VStack(spacing: 0) {
            ForEach(Array(axisTicks.enumerated()), id: \.offset) { index, tick in
                Text(tick.formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                if index < axisTicks.count - 1 { Spacer(minLength: 0) }
            }
        }
    }

    private var grid: some View {
        VStack(spacing: 0) {
            ForEach(Array(axisTicks.enumerated()), id: \.offset) { index, _ in
                Rectangle()
                    .fill(Color.secondary.opacity(index == axisTicks.count - 1 ? 0.26 : 0.16))
                    .frame(height: 1)
                if index < axisTicks.count - 1 { Spacer(minLength: 0) }
            }
        }
    }

    private var legend: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            legendItem(currentLabel, color: currentColor)
            legendItem(targetLabel, color: targetColor)
            HStack(spacing: 5) {
                Rectangle().fill(.secondary).frame(width: 18, height: 1)
                    .overlay { Rectangle().stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3])).foregroundStyle(.secondary) }
                Text(requirementLabel)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func height(_ value: Double) -> CGFloat {
        guard value.isFinite else { return 0 }
        return plotHeight * max(0, min(value / axisMaximum, 1))
    }

    private var barWidth: CGFloat { dynamicTypeSize.isAccessibilitySize ? 14 : 22 }
    private var currentColor: Color { Color(red: 0.42, green: 0.63, blue: 0.48) }
    private var targetColor: Color { Color(red: 0.09, green: 0.30, blue: 0.18) }

    private func legendItem(_ title: String, color: Color) -> some View {
        Label { Text(title) } icon: { RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 11, height: 11) }
    }

    private func statusTitle(_ status: String?) -> String {
        guard let status else { return "" }
        return status.components(separatedBy: " · ").last ?? status
    }

    private func statusColor(_ status: String?) -> Color {
        status?.localizedCaseInsensitiveContains("berlebih") == true ? .orange : Color(red: 0.55, green: 0.36, blue: 0.05)
    }
}
