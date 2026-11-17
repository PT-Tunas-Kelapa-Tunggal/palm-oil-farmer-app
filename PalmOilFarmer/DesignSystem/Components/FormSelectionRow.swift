import SwiftUI

struct FormSelectionRow: View {
    let title: String
    let placeholder: String
    let value: String?
    var systemImage: String? = nil
    var trailingImage = "chevron.right"
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KropsTheme.Spacing.field) {
            Text(title).font(KropsTheme.Typography.fieldLabel).foregroundStyle(.secondary)
            Button(action: action) {
                HStack(spacing: KropsTheme.Spacing.compact) {
                    if let systemImage {
                        Image(systemName: systemImage).foregroundStyle(.secondary)
                    }
                    Text(value ?? placeholder)
                        .foregroundStyle(value == nil ? KropsTheme.labelQuaternary : KropsTheme.labelPrimary)
                    Spacer()
                    Image(systemName: trailingImage).font(.footnote).foregroundStyle(.tertiary)
                }
                .font(KropsTheme.Typography.body)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(value ?? placeholder)
        }
    }
}

#Preview("Form Selection", traits: .sizeThatFitsLayout) {
    FormSelectionRow(title: "Jenis Tanah", placeholder: "Pilih jenis tanah", value: nil,
                     systemImage: "leaf.fill", action: {}).padding(16).frame(width: 370)
}
