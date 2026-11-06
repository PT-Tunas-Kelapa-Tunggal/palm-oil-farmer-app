import SwiftUI

struct FrequencyStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let label: String

    var body: some View {
        HStack(spacing: 0) {
            Button { value = max(range.lowerBound, value - 1) } label: {
                Image(systemName: "minus").font(.title2).frame(minWidth: 44, minHeight: 44)
            }
            .disabled(value <= range.lowerBound)
            Text(value.formatted()).font(.largeTitle.bold()).monospacedDigit()
                .frame(minWidth: 36)
            Button { value = min(range.upperBound, value + 1) } label: {
                Image(systemName: "plus").font(.title2).frame(minWidth: 44, minHeight: 44)
            }
            .disabled(value >= range.upperBound)
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
