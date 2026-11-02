import SwiftUI

/// A round icon, on a photo or on a light surface.
struct ReviewCircleIcon: View {
    enum Style {
        case onPhoto, onSurface
    }

    let systemImage: String
    var style = Style.onSurface
    var font = Font.body.weight(.semibold)
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(font)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .foregroundStyle(style == .onPhoto ? .white : .primary)
            .frame(width: size, height: size)
            .background(fill, in: Circle())
    }

    private var fill: AnyShapeStyle {
        style == .onPhoto ? AnyShapeStyle(.black.opacity(0.35)) : AnyShapeStyle(KropsTheme.secondaryFill)
    }
}

struct ReviewIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var style = ReviewCircleIcon.Style.onSurface
    var font = Font.body.weight(.semibold)
    var size: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ReviewCircleIcon(systemImage: systemImage, style: style, font: font, size: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Gaya ikon", traits: .sizeThatFitsLayout) {
    HStack(spacing: 8) {
        ReviewIconButton(systemImage: "xmark", accessibilityLabel: "Tutup", action: {})
        ReviewIconButton(systemImage: "chevron.left", accessibilityLabel: "Kembali", style: .onPhoto, action: {})
    }
    .padding(16)
    .background(.gray)
}
