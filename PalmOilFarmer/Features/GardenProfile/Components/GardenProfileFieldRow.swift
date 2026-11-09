import SwiftUI

struct GardenProfileFieldRow<Control: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    var message: String? = nil
    var minimumHeight: CGFloat = 82
    @ViewBuilder var control: () -> Control

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 16))
        layout {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.body)
                if let message { Text(message).font(.footnote).foregroundStyle(.secondary) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            control()
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)

    }
}

#if DEBUG
#Preview("Field · Frekuensi pemupukan", traits: .sizeThatFitsLayout) {
    @Previewable @State var frequency = 2
    GardenProfileFieldRow(title: "Frekuensi Pemupukan dalam setahun") {
        FrequencyStepper(value: $frequency, range: GardenProfileValidation.fertilizationFrequencyRange,
                         label: "Frekuensi pemupukan per tahun")
    }.padding().frame(width: 402)
}
#endif
