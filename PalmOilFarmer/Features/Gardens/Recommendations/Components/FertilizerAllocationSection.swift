import SwiftUI

struct FertilizerAllocationSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let period: FertilizerAllocationPeriod

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout())
        VStack(spacing: 8) {
            layout {
                Text(period.title).font(.headline)
                Spacer()
                Text(period.dateRange).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            VStack(spacing: 0) {
                ForEach(period.lines.indices, id: \.self) { index in
                    let line = period.lines[index]
                    layout {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.name).font(.headline)
                            Text(line.total).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(line.dosage).font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 12)
                    .frame(minHeight: 69)
                    if index < period.lines.count - 1 { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 24))
        }
    }
}
