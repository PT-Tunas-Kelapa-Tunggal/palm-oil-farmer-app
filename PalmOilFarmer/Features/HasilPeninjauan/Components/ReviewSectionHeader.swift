import SwiftUI

/// A section title with an optional subtitle or edit button.
struct ReviewSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var titleFont = Font.title3.bold()
    var editAccessibilityLabel: String? = nil
    var onEdit: (() -> Void)? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout())
        layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(titleFont)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if let onEdit {
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: KropsTheme.Spacing.compact)
                }
                Button(action: onEdit) {
                    Label("Ubah", systemImage: "pencil.line")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(editAccessibilityLabel ?? "Ubah")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, KropsTheme.Spacing.compact)
    }
}
