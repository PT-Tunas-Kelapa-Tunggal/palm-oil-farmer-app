import SwiftUI

struct GardenProfileFieldRow<Control: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    @ViewBuilder var control: () -> Control

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(spacing: 16))
        layout {
            Text(title).font(.body).frame(maxWidth: .infinity, alignment: .leading)
            control()
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(GardenProfileStyle.field, in: RoundedRectangle(cornerRadius: 24))
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
