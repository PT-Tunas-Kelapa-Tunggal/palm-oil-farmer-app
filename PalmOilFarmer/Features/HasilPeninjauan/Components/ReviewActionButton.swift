import SwiftUI

/// The full-width action button used across the review result screens.
struct ReviewActionButton: View {
    enum Style {
        case filled, surface, muted
    }

    let title: String
    let systemImage: String
    var iconLeads = false
    var style = Style.filled
    var font = Font.body.weight(.semibold)
    var minHeight: CGFloat = 52
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .font(font)
                .foregroundStyle(style == .filled ? Color(uiColor: .systemBackground) : .primary)
                .padding(KropsTheme.Spacing.compact)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .background(fill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var label: some View {
        if iconLeads {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
        } else {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: systemImage)
            }
        }
    }

    private var fill: AnyShapeStyle {
        switch style {
        case .filled: AnyShapeStyle(.primary)
        case .surface: AnyShapeStyle(.background)
        case .muted: AnyShapeStyle(KropsTheme.secondaryFill)
        }
    }
}

#Preview("Gaya tombol", traits: .sizeThatFitsLayout) {
    VStack(spacing: 8) {
        ReviewActionButton(title: "Filled", systemImage: "arrow.right", action: {})
        ReviewActionButton(title: "Surface", systemImage: "checkmark", iconLeads: true, style: .surface, action: {})
        ReviewActionButton(title: "Muted", systemImage: "arrow.right", style: .muted,
                           font: .subheadline.weight(.semibold), minHeight: 44, action: {})
    }
    .padding(16)
    .background(KropsTheme.background)
    .frame(width: 402)
}
