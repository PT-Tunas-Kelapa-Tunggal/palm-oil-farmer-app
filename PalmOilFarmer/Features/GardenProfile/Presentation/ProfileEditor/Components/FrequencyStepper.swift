import SwiftUI

struct FrequencyStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(value) kali").font(.title3.weight(.semibold)).fixedSize()
            HStack(spacing: 0) {
                Button { value = max(range.lowerBound, value - 1) } label: {
                    Image(systemName: "minus").font(.system(size: 20, weight: .medium)).frame(width: 44, height: 32)
                }.disabled(value <= range.lowerBound)
                Divider().frame(height: 24)
                Button { value = min(range.upperBound, value + 1) } label: {
                    Image(systemName: "plus").font(.system(size: 20, weight: .medium)).frame(width: 44, height: 32)
                }.disabled(value >= range.upperBound)
            }
            .font(.title3.weight(.semibold))
            .background(KropsTheme.surfaceCardRaised, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label).accessibilityValue(value.formatted())
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(range.upperBound, value + 1)
            case .decrement: value = max(range.lowerBound, value - 1)
            @unknown default: break
            }
        }
    }
}

#if DEBUG
#Preview("Stepper · Frekuensi panen", traits: .sizeThatFitsLayout) {
    @Previewable @State var frequency = 2
    FrequencyStepper(value: $frequency, range: HarvestRecord.frequencyRange,
                     label: "Frekuensi panen per bulan").padding()
}
#endif
