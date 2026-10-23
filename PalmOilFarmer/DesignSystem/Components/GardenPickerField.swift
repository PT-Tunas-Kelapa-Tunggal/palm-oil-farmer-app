import SwiftUI

struct GardenPickerField<Options: View>: View {
    let title: String
    let placeholder: String
    let value: String?
    let systemImage: String
    @ViewBuilder let options: () -> Options

    var body: some View {
        VStack(alignment: .leading, spacing: KropsTheme.Spacing.screen) {
            Text(title)
                .font(KropsTheme.Typography.fieldLabel)
                .foregroundStyle(.secondary)
            Menu(content: options) {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(value ?? placeholder)
                        .foregroundStyle(value == nil ? Color(uiColor: .placeholderText) : .primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .font(KropsTheme.Typography.body)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(value ?? placeholder)
            Divider()
        }
    }
}

#Preview("Garden Picker Field", traits: .sizeThatFitsLayout) {
    GardenPickerField(title: "Jenis Tanah", placeholder: "Pilih jenis tanah", value: nil, systemImage: "leaf.fill") {
        Button("Gambut") {}
        Button("Mineral") {}
    }
    .padding(16).frame(width: 402)
}
