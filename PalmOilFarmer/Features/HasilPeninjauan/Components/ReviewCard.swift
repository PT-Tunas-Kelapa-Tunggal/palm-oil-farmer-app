import SwiftUI

extension View {
    /// The rounded card behind content on the review result screens.
    func reviewCard(
        padding: CGFloat = KropsTheme.Spacing.section,
        fill: some ShapeStyle = .background,
        cornerRadius: CGFloat = KropsTheme.Radius.card
    ) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}
